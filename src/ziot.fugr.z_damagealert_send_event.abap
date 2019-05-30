FUNCTION Z_DAMAGEALERT_SEND_EVENT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SENSOR) TYPE  ZSENSOR DEFAULT 'SENSOR1'
*"     VALUE(PRIORITY) TYPE  ZPRIORITY DEFAULT 'M'
*"     VALUE(VIBRATIONLEVEL) TYPE  ZVIBRATION DEFAULT 99
*"     VALUE(PO_ID) TYPE  SNWD_PO_ID DEFAULT 0300000147
*"     VALUE(EMAIL) TYPE  AD_SMTPADR
*"     VALUE(ALERTID) TYPE  ZALERTID
*"  TABLES
*"      RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

**Info
* SEPMRACPOAPVPOI : Purchase Order Item View
* SEPMRACPOAPVPO : Purchase Order - contains Supplier (what if shopping cart = multiple Suppliers????
**

constants : c_msgclass        type SYMSGID value 'ZIOT',
            c_success         type bapi_mtype value 'S',
            c_failure         type bapi_mtype value 'E',
            c_m_xstring_error type symsgno value 3,
            c_m_send_error    type symsgno value 4,
            c_m_send_succ     type symsgno value 5.

CONSTANTS: gc_interface TYPE zinterface_id VALUE 'DAMAGE-EH'.

types: begin of t_product,
*        product_id      like SNWD_PRODUCT_ID,
        productname    like SEPMRACPOAPVPOI-PRODUCTNAME,
        quantity       like SEPMRACPOAPVPOI-Quantity,
        quantityunit   like SEPMRACPOAPVPOI-Quantityunit,
       end of t_product.

types : t_productlist     TYPE    STANDARD TABLE OF t_product with NON-UNIQUE key productname.

TYPES: BEGIN OF t_event_data,
         email            type    AD_SMTPADR,
         sensor           TYPE    zsensor,
         priority         TYPE    zpriority,
         vibrationlevel   TYPE    zvibration,
         alertid          TYPE    zalertid,
         po_id            TYPE    snwd_PO_id,
         productlist      TYPE    t_productlist,
       END OF t_event_data.

* tables : snwd_po, snwd_po_i, snwd_pd, snwd_texts.
tables : SEPMRACPOAPVPOI.

data: event_data         type t_event_data,
      purchaseoder       type sepmracpoapvpo,
      purchaseoder_items type sepmracpoapvpoi,
      productlist        type t_productlist,
*      product1           type t_product,
      product            type t_product.

data: it_headers         TYPE tihttpnvp,
      wa_headers         TYPE LINE OF tihttpnvp,
      lv_string          TYPE string,
      lv_response        TYPE string,
      cx_interface       TYPE REF TO zcx_interace_config_missing,
      cx_http            TYPE REF TO zcx_http_client_failed,
      cx_adf_service     TYPE REF TO zcx_adf_service,
      oref_eventhub      TYPE REF TO zcl_adf_service_eventhub,
      oref               TYPE REF TO zcl_adf_service,
      filter             TYPE zbusinessid,
      lv_http_status     TYPE i,
      lo_json            TYPE REF TO cl_trex_json_serializer,
      lv1_string         TYPE string,
      lv_xstring         TYPE xstring.

data : node_key          type SNWD_NODE_KEY,
       product_guid      type SNWD_NODE_KEY,
*       productid        type ,
       productname       like SEPMRACPOAPVPOI-productname,
       text_guid         type snwd_node_key.

move email          to event_data-email.
move sensor         to event_data-sensor.
move priority       to event_data-priority.
move vibrationlevel to event_data-vibrationlevel.
move po_id          to event_data-po_id.
move alertid        to event_data-alertid.

* Get List of items in the purchase Order
select productname, quantity, quantityunit from SEPMRACPOAPVPOI where purchaseorder = @po_id into table @DATA(it_products).
*select productname, quantity, quantityunit from SEPMRACPOAPVPOI where purchaseorder = po_id into product.
*
*  append product to productlist.
*endselect.

*product1-product_name  = 'product1'.
*product2-product_name  = 'product2'.
*append product1 to productlist.
*append product2 to productlist.

move it_products to event_data-productlist.

* Generate the alert
TRY.
**Calling Factory method to instantiate eventhub client

    oref = zcl_adf_service_factory=>create( iv_interface_id = gc_interface
                                            iv_business_identifier = filter ).
    oref_eventhub ?= oref.

**Setting Expiry time
    CALL METHOD oref_eventhub->add_expiry_time
      EXPORTING
        iv_expiry_hour = 0
        iv_expiry_min  = 15
        iv_expiry_sec  = 0.

    CREATE OBJECT lo_json
      EXPORTING
        data = event_data.

    lo_json->serialize( ).

    lv1_string  = lo_json->get_data( ).


*Convert input string data to Xstring format
    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text   = lv1_string
      IMPORTING
        buffer = lv_xstring
      EXCEPTIONS
        failed = 1
        OTHERS = 2.

    IF sy-subrc <> 0.
      return-type       = c_failure.
      return-id         = c_msgclass.
      return-number     = c_m_xstring_error.
      MESSAGE ID c_msgclass type c_success Number c_m_xstring_error into return-message.
      append return.
      exit.
    ENDIF.

*Sending Converted SAP data to Azure Eventhub
    CALL METHOD oref_eventhub->send
      EXPORTING
        request        = lv_xstring  "Input XSTRING of SAP Business Event data
        it_headers     = it_headers  "Header attributes
      IMPORTING
        response       = lv_response       "Response from EventHub
        ev_http_status = lv_http_status.   "Status

  CATCH zcx_interace_config_missing INTO cx_interface.
    lv_string = cx_interface->get_text( ).
**   MESSAGE lv_string TYPE 'E'.
    return-type       = c_failure.
    return-id         = c_msgclass.
    return-number     = c_m_send_error.
    MESSAGE ID c_msgclass type c_failure Number c_m_send_error with lv_string into return-message.
    append return.
    exit.
  CATCH zcx_http_client_failed INTO cx_http .
    lv_string = cx_http->get_text( ).
**    MESSAGE lv_string TYPE 'E'.
    return-type       = c_failure.
    return-id         = c_msgclass.
    return-number     = c_m_send_error.
    MESSAGE ID c_msgclass type c_failure Number c_m_send_error with lv_string into return-message.
    append return.
    exit.
  CATCH zcx_adf_service INTO cx_adf_service.
    lv_string = cx_adf_service->get_text( ).
**    MESSAGE lv_string TYPE 'E'.
    return-type       = c_failure.
    return-id         = c_msgclass.
    return-number     = c_m_send_error.
    MESSAGE ID c_msgclass type c_failure Number c_m_send_error with lv_string into return-message.
    append return.
    exit.
ENDTRY.

IF lv_http_status NE '201' AND
   lv_http_status NE '200'.
**  MESSAGE 'SAP data not sent to Azure EventHub' TYPE 'E'.
    return-type       = c_failure.
    return-id         = c_msgclass.
    return-number     = c_m_send_error.
    MESSAGE ID c_msgclass type c_failure Number c_m_send_error into return-message.
    append return.
ELSE.
**  MESSAGE 'SAP data sent to Azure EventHub' TYPE 'I'.
    return-type       = c_success.
    return-id         = c_msgclass.
    return-number     = c_m_send_succ.
    MESSAGE ID c_msgclass type c_success Number c_m_send_succ with lv_string into return-message.
    append return.
ENDIF.

ENDFUNCTION.
