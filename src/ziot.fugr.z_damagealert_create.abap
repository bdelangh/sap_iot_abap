FUNCTION Z_DAMAGEALERT_CREATE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SENSOR) TYPE  ZSENSOR DEFAULT 'Sensor1'
*"     VALUE(PRIORITY) TYPE  ZPRIORITY DEFAULT 'M'
*"     VALUE(VIBRATIONLEVEL) TYPE  ZVIBRATION DEFAULT 99
*"  EXPORTING
*"     VALUE(RET_ALERTID) TYPE  ZALERTID
*"  TABLES
*"      RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

**Info
* SEPMRACPOAPVPOI : Purchase Order Item View
* SEPMRACPOAPVPO : Purchase Order - contains Supplier (what if shopping cart = multiple Suppliers????
**
tables: zdamagealert, snwd_po, zsensor_data.
tables: sepm_iuser.


constants : c_msgclass      type SYMSGID value 'ZIOT',
            c_success       type bapi_mtype value 'S',
            c_failure       type bapi_mtype value 'E',
            c_m_inserted    type symsgno value 0,
            c_m_genalert    type symsgno value 1,
            c_m_inserterror type symsgno value 2.

*Data for send event
data : send_event  type abap_bool,
       i_return    type table of BAPIRET2 with header line,
       i_bapi_smtp type table of BAPIADSMTP,
       r_bapi_smtp like BAPIADSMTP,
       username    like BAPIBNAME-BAPIBNAME,
       email       like BAPIADSMTP-E_MAIL.

* Determine the alert id
data: new_alertid  type zalertid.
data: old_alertid  type zalertid.
data: alertrecord  type zdamagealert.
data: currenttimestamp type timestamp.

GET TIME STAMP FIELd currenttimestamp.

*send_event = abap_false.
send_event = abap_true.

* determine PO Nr = most recent PO
data user_name type xubname.
select single uname from zsensor_data where sensorid = @sensor into @user_name.

data useruuid like sepm_iuser-useruuid.
select single useruuid from sepm_iuser where userid = @user_name into @useruuid.

data : po_id type snwd_po_id.
select * from snwd_po where created_by = @useruuid
                      order by created_at descending
                      into @data(result)
                      up to 1 rows.
  po_id = result-po_id.
endselect.

* Determine max alertID
select single max( alertid ) from zdamagealert into old_alertid.
if sy-subrc ne 0.
    "AlertId could not be determined
    return-type   = c_failure.
    return-id     = c_msgclass.
    return-number = c_m_genalert.
    MESSAGE ID c_msgclass type c_failure Number c_m_genalert into return-message.
    append return.
    exit.
endif.

new_alertid = old_alertid + 10.
ret_alertid = new_alertid.
move new_alertid      to alertrecord-alertid.
move po_id            to alertrecord-po_id.
move sensor           to alertrecord-sensor.
move priority         to alertrecord-priority.
move vibrationlevel   to alertrecord-vibrationlevel.
move sy-uname         to alertrecord-createdby.
move currenttimestamp to alertrecord-createdate.

insert into zdamagealert values alertrecord.
if sy-subrc ne 0.
   "Insert Not Successfull
    return-type       = c_failure.
    return-id         = c_msgclass.
    return-number     = c_m_inserterror.
    return-message_v1 = new_alertid.
    MESSAGE ID c_msgclass type c_failure Number c_m_inserterror with new_alertid into return-message.
    append return.
    exit.
endif.

* Add SuccessFull message
return-type = c_success.
return-id = c_msgclass.
return-number = c_m_inserted.
return-message_v1 = new_alertid.
MESSAGE ID c_msgclass type c_success Number c_m_inserted with new_alertid into return-message.
append return.

* Send Event email
if send_event = abap_true.
* Determine email
  select single email from zsensor_data where sensorid = @sensor into @email.

* Call the send event function
    call function 'Z_DAMAGEALERT_SEND_EVENT'
      exporting
         sensor = sensor
         priority = priority
         vibrationlevel = vibrationlevel
         po_id = po_id
         email = email
         alertid = new_alertid
      tables
         return = i_return.

* Add messages to return output
  loop at i_return.
     append i_return to return.
  endloop.
endif.

ENDFUNCTION.
