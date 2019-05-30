FUNCTION Z_TEMPALERT_CREATE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(EQUIPMENT) TYPE  ZEQUIPMENT
*"     VALUE(SENSOR) TYPE  ZSENSOR
*"     VALUE(PRIORITY) TYPE  ZPRIORITY
*"     VALUE(TEMPERATURE) TYPE  ZTEMPERATURE
*"  TABLES
*"      RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

*Creates an entry in the Temperature Alert table ztempalert.
tables: ztempalert.

constants : c_msgclass      type SYMSGID value 'ZIOT',
            c_success       type bapi_mtype value 'S',
            c_failure       type bapi_mtype value 'E',
            c_m_inserted    type symsgno value 0,
            c_m_genalert    type symsgno value 1,
            c_m_inserterror type symsgno value 2.

* Determine the alert id
data: new_alertid type zalertid.
data: old_alertid type zalertid.
data: alertrecord type ztempalert.
data: currenttimestamp type timestamp.

GET TIME STAMP FIELd currenttimestamp.

* Determine max alertID
select single max( alertid ) from ztempalert into old_alertid.
if sy-subrc ne 0.
    "AlertId could not be determined
    return-type   = c_failure.
    return-id     = c_msgclass.
    return-number = c_m_genalert.
    MESSAGE ID c_msgclass type c_success Number c_m_genalert into return-message.
    append return.
    exit.
endif.

new_alertid = old_alertid + 10.
move new_alertid      to alertrecord-alertid.
move equipment        to alertrecord-equipment.
move sensor           to alertrecord-sensor.
move priority         to alertrecord-priority.
move sy-uname         to alertrecord-createdby.
move temperature      to alertrecord-temperature.
move currenttimestamp to alertrecord-createdate.

insert into ztempalert values alertrecord.
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

ENDFUNCTION.
