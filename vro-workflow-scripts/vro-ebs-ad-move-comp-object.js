for(var c in vm_arr_out) {
	System.log("VM Name: " + vm_arr_out[c]);
	var object = ActiveDirectory.getComputerAD(vm_arr_out[c],addc);

	System.log("Searching for computer: " + vm_arr_out[c])
	System.log("Found computer: " + object)

    //Move object to specified OU
	ActiveDirectory.rename(object.distinguishedName, "CN= " +vm_arr_out[c] , "Insert desired destination OU Distinguished name" , addc)
}