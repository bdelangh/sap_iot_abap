class ZCL_DAMAGEALERT_REST_HANDLER definition
  public
  inheriting from CL_REST_HTTP_HANDLER
  final
  create public .

public section.

  methods IF_REST_APPLICATION~GET_ROOT_HANDLER
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_DAMAGEALERT_REST_HANDLER IMPLEMENTATION.


  method IF_REST_APPLICATION~GET_ROOT_HANDLER.
    DATA(lo_router) = NEW cl_rest_router( ).
    lo_router->attach( iv_template = '/create' iv_handler_class = 'ZCL_DAMAGEALERT_REST_RESOURCE' ).

    ro_root_handler = lo_router.




*CALL METHOD SUPER->IF_REST_APPLICATION~GET_ROOT_HANDLER
*  RECEIVING
*    RO_ROOT_HANDLER =
*    .
  endmethod.
ENDCLASS.
