class ZCL_CUTE_CUSTOMIZING_REQUEST definition
  public
  final
  create public .

public section.

  interfaces ZIF_CUTE_CUSTOMIZING_REQUEST .

  methods CONSTRUCTOR
    importing
      !I_REQUEST type E071-TRKORR optional
      !I_TASK type E071-TRKORR optional .
  PROTECTED SECTION.
private section.

  data REQUEST type E071-TRKORR .
  data TASK type E071-TRKORR .
  data:
    e071_entries TYPE TABLE OF e071 .
  data:
    e071k_entries TYPE TABLE OF e071k .
  data KO200 type KO200 .

  methods VALIDATE_INPUT
    importing
      !TABLE_NAME type TABNAME
      !TABLE_KEY type TROBJ_NAME
    raising
      ZCX_CUTE_NO_REQUEST
      ZCX_CUTE_TABLE_DOES_NOT_EXIST
      ZCX_CUTE_KEY_NOT_VALID .
ENDCLASS.



CLASS ZCL_CUTE_CUSTOMIZING_REQUEST IMPLEMENTATION.


  METHOD constructor.
    request = i_request.
    task = i_task.
  ENDMETHOD.


  METHOD validate_input.
    DATA subrc LIKE sy-subrc.

    IF request IS INITIAL AND task IS INITIAL.
      RAISE EXCEPTION TYPE zcx_cute_no_request.
    ENDIF.
    " another check if the table does exist in DDIC will come later
    IF table_name IS INITIAL.
      RAISE EXCEPTION TYPE zcx_cute_table_does_not_exist.
    ENDIF.
    " another check if the key is more or less valid to the table key will come later ( empty key is not valid ^^ )
    IF table_key IS INITIAL.
      RAISE EXCEPTION TYPE zcx_cute_key_not_valid.
    ENDIF.

    CALL FUNCTION 'DB_EXISTS_TABLE'
      EXPORTING
        tabname = table_name
      IMPORTING
        subrc   = subrc.

    IF subrc <> 0.
      RAISE EXCEPTION TYPE zcx_cute_table_does_not_exist.
    ENDIF.

  ENDMETHOD.


  METHOD zif_cute_customizing_request~add_key_to_request.
    validate_input( table_name = table_name table_key = table_key ).

    DATA(e071k) = VALUE e071k( object = 'TABU'
                               objname = table_name
                               tabkey = table_key
                               pgmid = 'R3TR'
                               objfunc = 'K'
                               as4pos = 0
                               mastername = table_name
                               mastertype = 'TABU' ).

    ko200 = CORRESPONDING ko200( e071k ).

    APPEND e071k TO e071k_entries.

    CALL FUNCTION 'TR_OBJECT_CHECK'
      EXPORTING
        wi_ko200 = ko200.

    CALL FUNCTION 'TR_OBJECT_INSERT'
      EXPORTING
        wi_order                = zif_cute_customizing_request~get_request( )
        wi_ko200                = ko200    " Eingabe editiertes Objekt
      TABLES
        wt_e071k                = e071k_entries    " Eingabetabelle editierter Objekt-keys
      EXCEPTIONS
        cancel_edit_other_error = 1
        show_only_other_error   = 2
        OTHERS                  = 3.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDMETHOD.


  METHOD zif_cute_customizing_request~get_request.
    IF task IS INITIAL.
      r_request = request.
    ELSE.
      r_request = task.
    ENDIF.
  ENDMETHOD.


  METHOD zif_cute_customizing_request~set_request_via_popup.

    CALL FUNCTION 'TRINT_ORDER_CHOICE'
      EXPORTING
        wi_order_type          = 'W'
        wi_task_type           = 'Q'
        wi_category            = 'CUST'
      IMPORTING
        we_order               = request
        we_task                = task
      TABLES
        wt_e071                = e071_entries
        wt_e071k               = e071k_entries
      EXCEPTIONS
        no_correction_selected = 1
        display_mode           = 2
        object_append_error    = 3
        recursive_call         = 4
        wrong_order_type       = 5
        OTHERS                 = 6.

  ENDMETHOD.
ENDCLASS.
