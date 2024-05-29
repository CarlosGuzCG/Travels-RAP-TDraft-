CLASS zcl_cg_data_generator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    interfaces if_oo_adt_classrun.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CG_DATA_GENERATOR IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    out->write( |---> Travel| ).

    delete from ztravel_cg_a.
    DELETE from ztravel_cg_d.

    insert ztravel_cg_a from (
        select from /dmo/travel fields
            " client
            uuid( ) as travel_uuid,
            travel_id,
            agency_id,
            customer_id,
            begin_date,
            end_date,
            booking_fee,
            total_price,
            currency_code,
            description,
            case status when 'B' then 'A'
                        when 'P' then 'O'
                        when 'N' then 'O'
                        else 'X' end as overall_status,
            createdby as local_created_by,
            createdat as local_created_at,
            lastchangedby as local_last_changed_by,
            lastchangedat as local_last_changed_at,
            lastchangedat as last_changed_at
            where travel_id BETWEEN '00000001' and '00000055'
     ).

     if sy-subrc eq 0.
       out->write( |Travel entries insertd: { sy-dbcnt }| ).
     endif.

     " bookings
     out->write( |---> Bookings | ).

     delete from zbooking_cg_a. "#EC CI_NOWHERE
     delete from zbooking_cg_d. "#EC CI_NOWHERE

     insert zbooking_cg_a from (
        select
            from /dmo/booking
                join ztravel_cg_a on
                    /dmo/booking~travel_id = ztravel_cg_a~travel_id
                join /dmo/travel on /dmo/travel~travel_id = /dmo/booking~travel_id
            fields "client,
                UUID( ) as booking_uuid,
                ztravel_cg_a~travel_uuid as parent_uuid,
                /dmo/booking~booking_id,
                /dmo/booking~booking_date,
                /dmo/booking~customer_id,
                /dmo/booking~carrier_id,
                /dmo/booking~connection_id,
                /dmo/booking~flight_date,
                /dmo/booking~flight_price,
                /dmo/booking~currency_code,
                case /dmo/travel~status when 'P' then 'N'
                    else /dmo/travel~status end as booking_status,
                ztravel_cg_a~last_changed_at as local_last_changed_at
         ).

     if sy-subrc eq 0.
       out->write( |Travel entries insertd: { sy-dbcnt }| ).
     endif.

     " supplements
     out->write( |----> Booking | ).

     delete from zbksuppl_cg_a.
     delete from zbksuppl_cg_d.

     insert zbksuppl_cg_a from (
        select from /dmo/book_suppl as supp
            join ztravel_cg_a as trvl on trvl~travel_id = supp~travel_id
            join zbooking_cg_a as book on book~parent_uuid = trvl~travel_uuid
                                       and book~booking_id = supp~booking_id
           fields
           " client
           uuid( ) as booksuppl_uuid,
           trvl~travel_uuid as root_uuid,
           book~booking_uuid as parent_uuid,
           supp~booking_supplement_id,
           supp~supplement_id as supplement_id,
           supp~price,
           supp~currency_code,
           trvl~last_changed_at as local_last_changed_at

      ).

     if sy-subrc eq 0.
       out->write( |Travel entries insertd: { sy-dbcnt }| ).
     endif.

     out->write( |----> zbksuppl_cg_a | ).

  ENDMETHOD.
ENDCLASS.
