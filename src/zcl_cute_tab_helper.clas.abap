class ZCL_CUTE_TAB_HELPER definition
  public
  final
  create public .

public section.

  class-methods GET_INSTANCE
    importing
      !SOURCE_INFO type ref to ZIF_CUTE_SOURCE_INFO
    returning
      value(INSTANCE) type ref to ZCL_CUTE_TAB_HELPER .
  methods SET_SOURCE
    importing
      !SOURCE_INFO type ref to ZIF_CUTE_SOURCE_INFO .
  methods GET_COMPONENTS
    returning
      value(COMPONENTS) type CL_ABAP_STRUCTDESCR=>COMPONENT_TABLE .
  methods SET_COMPONENTS
    importing
      !COMPONENTS type CL_ABAP_STRUCTDESCR=>COMPONENT_TABLE .
  methods GET_DATA_REFERENCE_EDIT
    returning
      value(DATAREF) type ref to DATA .
  methods GET_DATA_REFERENCE_ORIGIN
    returning
      value(DATAREF) type ref to DATA .
  methods GET_FIELD_CATALOG
    importing
      !GRID type ref to CL_GUI_ALV_GRID
      !EDIT type FLAG
    returning
      value(FCAT) type LVC_T_FCAT .
protected section.
  PRIVATE SECTION.
    METHODS create.
    DATA struc_origin_descr TYPE REF TO cl_abap_structdescr.
    DATA table_origin_descr TYPE REF TO cl_abap_tabledescr.
    DATA table_origin_data TYPE REF TO data.

    DATA table_edit_data TYPE REF TO data.
    DATA table_edit_descr TYPE REF TO cl_abap_tabledescr.
    DATA struc_edit_descr TYPE REF TO cl_abap_structdescr.
    DATA source_information TYPE REF TO zif_cute_source_info.
    DATA components TYPE cl_abap_structdescr=>component_table.
ENDCLASS.



CLASS ZCL_CUTE_TAB_HELPER IMPLEMENTATION.


  METHOD create.
    struc_origin_descr = CAST cl_abap_structdescr( cl_abap_structdescr=>describe_by_name( source_information->name ) ).

    "Needed to save data
    table_origin_descr = cl_abap_tabledescr=>create(
      p_line_type  = struc_origin_descr
      p_table_kind = cl_abap_tabledescr=>tablekind_std
      p_unique     = abap_false ).

    CREATE DATA table_origin_data TYPE HANDLE table_origin_descr.

    "Adapt editable structure
    components = struc_origin_descr->get_components( ).

    APPEND VALUE #( name = '_COLOR_' type = CAST cl_abap_datadescr( cl_abap_structdescr=>describe_by_name( 'LVC_T_SCOL' ) ) )
    TO components.

    struc_edit_descr = cl_abap_structdescr=>create( components ).

    table_edit_descr = cl_abap_tabledescr=>create(
      p_line_type  = struc_edit_descr
      p_table_kind = cl_abap_tabledescr=>tablekind_std
      p_unique     = abap_false ).

    CREATE DATA table_edit_data TYPE HANDLE table_edit_descr.
  ENDMETHOD.


  METHOD get_components.
  ENDMETHOD.


  METHOD get_data_reference_edit.
    dataref = table_edit_data.
  ENDMETHOD.


  METHOD get_data_reference_origin.
    dataref = table_origin_data.
  ENDMETHOD.


  METHOD get_field_catalog.
    DATA element_descr TYPE REF TO cl_abap_elemdescr.
    DATA field_descr TYPE dfies.

    LOOP AT components INTO DATA(component).
      TRY.
          element_descr ?= component-type.
          field_descr = element_descr->get_ddic_field( ).
          CHECK field_descr-datatype <> 'CLNT'.
          APPEND INITIAL LINE TO fcat ASSIGNING FIELD-SYMBOL(<field>).
          MOVE-CORRESPONDING field_descr TO <field>.
          <field>-fieldname = component-name.
          <field>-reptext   = field_descr-fieldname.
          <field>-scrtext_s = field_descr-fieldname.
          <field>-scrtext_m = field_descr-fieldname.
          <field>-scrtext_l = field_descr-fieldname.
          <field>-ref_table = source_information->name.

          DATA(field_info) = source_information->get_field_info( component-name ).
          IF field_info-cute-read_only = abap_false.
            <field>-edit      = edit.
          ENDIF.

          CASE field_info-cute-fieldtype.
            WHEN 'CB'.
              <field>-checkbox = abap_true.
            WHEN 'LK' OR 'LT' OR 'LB'.
              <field>-drdn_hndl  = field_info-dfies-position.
              <field>-drdn_alias = 'X'.
              grid->set_drop_down_table(
                  it_drop_down_alias = zcl_cute_listbox_helper=>get_listbox_for_fix_values(
                    handle  = <field>-drdn_hndl
                    type    = field_info-cute-fieldtype
                    domname = field_info-dfies-domname ) ).
            WHEN 'IC'.
              <field>-icon = abap_true.

          ENDCASE.

        CATCH cx_sy_move_cast_error.
          CONTINUE.
      ENDTRY.

    ENDLOOP.
  ENDMETHOD.


  METHOD get_instance.
    instance = NEW zcl_cute_tab_helper( ).
    instance->set_source( source_info ).
    instance->create( ).
  ENDMETHOD.


  METHOD set_components.
  ENDMETHOD.


  METHOD set_source.
    source_information = source_info.
  ENDMETHOD.
ENDCLASS.
