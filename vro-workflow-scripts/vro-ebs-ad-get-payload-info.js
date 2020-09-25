//vRO JavaScript Workflow to get deployemnt info from vRA provided payload, find vm information, and pass to ActiveDirectory Tasks
//
//----Variables
//----------------------
var vm_list = new Array();
var deploymentName = "";
var deploymentStatus = "";
var vraHost = "";
var reqId = "";
var infraVirtual = false;
var i = 0;
var ii = 0;
//-----------------------
// Define desired vRA host from inventory to use for API calls. 
var vraHost = Server.findAllForType("vCACCAFE:VCACHost")[0];
System.log(vraHost);

// Save the catalogRequestId from the payload given by vRA 
var reqId = payload.get("catalogRequestId").toString();
System.log("catalogRequestId: " + reqId);

// Create a REST client on the selected vRA host, which we can use to do API calls against
var client = vraHost.createCatalogClient();

//Get deployment Status and Monitor until status is ACTIVE/COMPLETE
do {
    // Get the Deployment info from the catalogRequestId
    var response = client.get("/consumer/requests/" + reqId +"/resources").getBodyAsJson();
    //for (var k in response) {
     //System.log("API return: " + response[k]);
    //}
    for(var x in response.content)
    {
        var resource = response.content[x];
        //System.log("Response.content:" + resource);
        //Get Deployment Name and Status
        if(resource.resourceTypeRef.id == "composition.resource.type.deployment") {
            deploymentName = resource.name;
            deploymentStatus = resource.status;
        }
        System.log("Deployment name: " + deploymentName);
        System.log("Deployment Status: " + deploymentStatus);
    }
    
    //System.log("Waiting 3s to continue...");
    //System.sleep(3000);
   i++;
        
}
while (deploymentStatus != "ACTIVE" && i < 4);

//Once Deployment Complete Check if VM information has been written to database via API call
do {
    var response = client.get("/consumer/requests/" + reqId +"/resources").getBodyAsJson();
    for(var x in response.content)
        {
            var resource = response.content[x];
            // if the resourceTypeRef { "id": "Infrastructure.Virtual" } -> it's a virtual machine
            //System.log("Response.content:" + resource);
            if(resource.resourceTypeRef.id == "Infrastructure.Virtual" && resource.name != null) 
                {
                    System.log ("Deployment VM Info found via API object response");
                    infraVirtual = true;
                }
            else
                {
                    System.log ("Deployment VM Info not found in API object response");     
                }
        }
    if (infraVirtual != true)
        {
            System.log ("Deployment VM Info not available to API yet, waiting 10s...");
            System.sleep(10000);
            ii++;
        }
}
while (infraVirtual != true && ii < 30); 
// Temp Check API logic
if (infraVirtual = false) 
    {
        System.log ("Deployment VM Info was not made available to API, check vRA");
    }
//Once Deployemnet is ACTIVE/COMPLETE make final API call to get full Deployment Info
var response = client.get("/consumer/requests/" + reqId +"/resources").getBodyAsJson();
    //for (var k in response) {
     //System.log("API return: " + response[k]);
    //}
for(var x in response.content)
{
  var resource = response.content[x];
  // if the resourceTypeRef { "id": "Infrastructure.Virtual" } -> it's a virtual machine
  //System.log("Response.content:" + resource);
  if(resource.resourceTypeRef.id == "Infrastructure.Virtual") 
  {
    // placeholder var for the VM tier
    var tierName = "";
    // go find the tier name in the key/value array, the key is called "Component"
    for(var k in resource.resourceData.entries) {
      var property = resource.resourceData.entries[k];
      if(property.key == "Component") tierName = property.value.value;
    }
    // construct an array to hold the VM info that we want to store and save it to vm_list for later use
    var vm_info = new Array();
    vm_info['name'] = resource.name;
    vm_info['tier'] = tierName;
    vm_info['id'] = resource.id;
    vm_list.push(vm_info);
  }
}

// Do things with the deployment name and list of VMs we've just queried vRA for.

// List VMs
for(var r in vm_list) {
  System.log("VM Name: " + vm_list[r].name + " ; id = " + vm_list[r].id);
  var vm_arr_out = new Array();
  vm_arr_out.push(vm_list[r].name);
  //vm_list[r].name.push(vm_arr_out);
  System.log("var_out:" + vm_arr_out);
}
