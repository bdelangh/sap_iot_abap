*&---------------------------------------------------------------------*
*& Report ZDAMAGEALERT_DELETE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZDAMAGEALERT_DELETE.

tables: zdamagealert.

delete from zdamagealert where alertid > 40.
