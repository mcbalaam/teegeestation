/datum/component/barcode
    /// The value stored on the barcode.
    var/barcode_value = null
    /// Readable text (if any) accompanying the barcode.
    var/hri_text = null

    /// Custom prefix
    var/examine_prefix = ""

/datum/component/barcode/can_attach(atom/target)
    return istype(target, /atom)

/datum/component/barcode/Initialize(atom/target, value, hri = null)
	if(!..())
		return COMPONENT_INCOMPATIBLE
	if(value)
		barcode_value = "[value]"
	else
		barcode_value = "[REF(target)]"

	hri_text = hri

	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

	return COMPONENT_INITIALIZED

/datum/component/barcode/Destroy(force)
	UnregisterSignal(parent, COMSIG_ATOM_EXAMINE)
	..()

/datum/component/barcode/proc/on_scanned(mob/user, obj/tool)
	if(!enabled || !barcode_value)
		return null
	SEND_SIGNAL(parent, COMSIG_BARCODE_SCANNED, user, tool)
	return barcode_value

/datum/component/barcode/proc/on_examine(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(!barcode_value)
		return

	var/list/hints = examine_list[EXAMINE_HINTS]
	if(!islist(hints))
		hints = list()
		examine_list[EXAMINE_HINTS] = hints

	hints =+ "It has a barcode attached. You can take a closer look..."
