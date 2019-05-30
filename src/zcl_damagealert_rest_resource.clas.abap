class ZCL_DAMAGEALERT_REST_RESOURCE definition
  public
  inheriting from CL_REST_RESOURCE
  final
  create public .

public section.

  methods IF_REST_RESOURCE~GET
    redefinition .
  methods IF_REST_RESOURCE~POST
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_DAMAGEALERT_REST_RESOURCE IMPLEMENTATION.


  method IF_REST_RESOURCE~GET.
*CALL METHOD SUPER->IF_REST_RESOURCE~GET
*    .
    mo_response->create_entity( )->set_string_data( `Use Post method to create a Damage Alert!` ).
  endmethod.


  method IF_REST_RESOURCE~POST.

    data: begin of ls_alert,
        sensor type zsensor,
        priority type zpriority,
        vibrationlevel type zvibration,
    end of ls_alert.

    DATA(lv_request_body) = mo_request->get_entity( )->get_string_data( ).
    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_body CHANGING data = ls_alert ).

    data: sensor type zsensor,
          priority type zpriority,
          vibrationlevel type zvibration,
          i_return type table of bapiret2.

    sensor = ls_alert-sensor.
    priority = ls_alert-priority.
    vibrationlevel = ls_alert-vibrationlevel.

    call function 'Z_DAMAGEALERT_CREATE'
      exporting
        sensor = sensor
        priority = priority
        vibrationlevel = vibrationlevel
       tables
         return = i_return.

    DATA(lo_entity) = mo_response->create_entity( ).
    lo_entity->set_content_type( if_rest_media_type=>gc_appl_json ).
    lo_entity->set_string_data( /ui2/cl_json=>serialize( i_return ) ).
    mo_response->set_status( cl_rest_status_code=>gc_success_ok ).



*CALL METHOD SUPER->IF_REST_RESOURCE~POST
*  EXPORTING
*    IO_ENTITY =
*    .
  endmethod.
ENDCLASS.
