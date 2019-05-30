FUNCTION Z_IOTALERT_CREATE_PRIO.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SENSOR) TYPE  ZSENSOR
*"     VALUE(VALUE) TYPE  ZALERTVALUE
*"     VALUE(PRIORITY) TYPE  ZPRIORITY
*"  EXPORTING
*"     VALUE(RET_ALERTID) TYPE  ZALERTID
*"  TABLES
*"      RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------
* Creates an entry in the IoT Alert Table
tables: ziotalert, ziotsensor.

constants : c_msgclass      type SYMSGID value 'ZIOT',
            c_success       type bapi_mtype value 'S',
            c_failure       type bapi_mtype value 'E',
            c_m_inserted    type symsgno value 0,
            c_m_genalert    type symsgno value 1,
            c_m_inserterror type symsgno value 6.

data : send_event  type abap_bool,
       i_return    type table of BAPIRET2 with header line.

*send_event = abap_false.
send_event = abap_true.

*Determine the alert id
data: new_alertid type zalertid.
data: old_alertid type zalertid.
data: alertrecord type ziotalert.
data: currenttimestamp type timestamp.

GET TIME STAMP FIELd currenttimestamp.

* Determine max alertID
select single max( alertid ) from ziotalert into old_alertid.
if sy-subrc ne 0.
    "AlertId could not be determined
    return-type   = c_failure.
    return-id     = c_msgclass.
    return-number = c_m_genalert.
    MESSAGE ID c_msgclass type c_success Number c_m_genalert into return-message.
    append return.
    exit.
endif.

data: iotsensor type ziotsensor.

select single * from ziotsensor into ziotsensor where sensorid = sensor.

new_alertid = old_alertid + 10.
ret_alertid = new_alertid.
move new_alertid                 to alertrecord-alertid.
move ziotsensor-equipment        to alertrecord-equipment.
move ziotsensor-alerttype        to alertrecord-alerttype.
move sensor                      to alertrecord-sensor.
move priority                    to alertrecord-priority.
move sy-uname                    to alertrecord-createdby.
move value                       to alertrecord-value.
move currenttimestamp to alertrecord-createdate.

insert into ziotalert values alertrecord.
if sy-subrc ne 0.
   "Insert Not Successfull
    return-type       = c_failure.
    return-id         = c_msgclass.
    return-number     = c_m_inserterror.
    return-message_v1 = new_alertid.
    MESSAGE ID c_msgclass type c_success Number c_m_inserterror with new_alertid into return-message.
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

if send_event = abap_true.

* Call the send event function
    call function 'Z_IOTALERT_SEND_EVENT'
      exporting
         alertid   = new_alertid
         sensor    = sensor
         equipment = ziotsensor-equipment
         priority  = priority
         alerttype = ziotsensor-alerttype
         value     = value
         email     = ziotsensor-email
      tables
         return = i_return.

* Add messages to return output
  loop at i_return.
     append i_return to return.
  endloop.
endif.



ENDFUNCTION.
