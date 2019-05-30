FUNCTION Z_IOTALERT_SEND_EVENT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(ALERTID) TYPE  ZALERTID
*"     REFERENCE(SENSOR) TYPE  ZSENSOR
*"     REFERENCE(EQUIPMENT) TYPE  ZEQUIPMENT
*"     REFERENCE(PRIORITY) TYPE  ZPRIORITY
*"     REFERENCE(ALERTTYPE) TYPE  ZALERTTYPE
*"     REFERENCE(VALUE) TYPE  ZALERTVALUE
*"     REFERENCE(EMAIL) TYPE  AD_SMTPADR
*"  TABLES
*"      RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------
constants : c_msgclass        type SYMSGID value 'ZIOT',
            c_success         type bapi_mtype value 'S',
            c_failure         type bapi_mtype value 'E',
            c_m_xstring_error type symsgno value 3,
            c_m_send_error    type symsgno value 4,
            c_m_send_succ     type symsgno value 7.

CONSTANTS: gc_interface TYPE zinterface_id VALUE 'IOT-EH'.

TYPES: BEGIN OF t_event_data,
         alertid          type    zalertid,
         alerttype        type    zalerttype,
         email            type    AD_SMTPADR,
         sensor           TYPE    zsensor,
         equipment        type    zequipment,
         priority         TYPE    zpriority,
         value            TYPE    zalertvalue,
       END OF t_event_data.

data: event_data         type t_event_data.

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

move alertid        to event_data-alertid.
move alerttype      to event_data-alerttype.
move email          to event_data-email.
move sensor         to event_data-sensor.
move equipment      to event_data-equipment.
move priority       to event_data-priority.
move value          to event_data-value.

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
