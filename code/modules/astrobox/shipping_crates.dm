#define STATUS_ASSEMBLING "Assembling"
#define STATUS_SHIPPED "Shipped"
#define STATUS_SORTING "Sorting"
#define STATUS_PENDING "Pending Pickup"
#define STATUS_DELIVERED "Picked Up"
#define STATUS_CANCELLED "Cancelled"

/// A generic AstroBox delivery crate containing customer goods.
/datum/shipping_crate
	/// A unique shipment `id` used to identify this shipment.
	var/shipping_id = "0x0000000"
	/// A list of individual packages inside this shipment.
	var/orders = list()

/// A generic AstroBox order datum.
/datum/astrobox_order
	/// The `id` the system identifies this order by.
	var/order_id = "0x000000"
	/// The display name visible in the interface.
	var/display_name = "generic order"

/datum/astrobox_order/New()
	order_id = REF(src)

/datum/astrobox_order_position
	/// The status of this order position.
	var/status = STATUS_ASSEMBLING
	/// The path of the atom this order position is resembling.
	var/atom_path = null

/// Compiles some data about the reference atom to show in the UI.
/datum/astrobox_order_position/proc/provide_atom_data()
	var/list/item_data = list(
		"name" = atom_path.name,
		"icon" = atom_path.greyscale_config ? null : atom_path.icon,
		"icon_state" = atom_path.greyscale_config ? null : atom_path.icon_state
	)
