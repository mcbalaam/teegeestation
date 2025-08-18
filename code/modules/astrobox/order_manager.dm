#define SHIPMENT_ORDER_LIMIT 10
#define SHIPMENT_AMOUNT_MAX 8

/obj/machinery/astrobox_order
	/// All active shipments.
	var/shipments = list()

/obj/machinery/astrobox_order/proc/create_new_shipment()
	var/datum/shipping_crate/current_crate = new /datum/shipping_crate
	shipments += current_crate
	return current_crate

// /obj/machinery/astrobox_order/proc/assign_order_to_shipment(datum/astrobox_order/order)
// 	var/datum/shipping_crate/selected_shipment = null

// 	// If there's empty space in one of the active shipments...
// 	for(var/datum/shipping_crate/each_shipment in shipments)
// 		if(length(each_shipment.orders) >= SHIPMENT_ORDER_LIMIT)
// 			continue
// 		else
// 			selected_shipment = each_shipment	// ...then put the order there.

// 	if(!selected_shipment)
// 		selected_shipment = create_new_shipment()	// If not - create a new one.

// 	selected_shipment.orders += order

/obj/machinery/astrobox_order/proc/get_fitting_shipment()
	// magic happens here
	return fitting_shipment

/obj/machinery/astrobox_order/proc/assemble_supply_pack(datum/supply_pack/some_pack)
	var/datum/shipping_crate/target_shipment = null
	for(var/path in supply_pack.contains)
	 	fitting_shipment = get_fitting_shipment()



/obj/machinery/astrobox_order/proc/ship()
	for(var/datum/shipping_crate/each_shipment in shipments)
		for(var/datum/astrobox_order_position/each_position in each_shipment.orders)
			each_position.status = STATUS_SHIPPED



