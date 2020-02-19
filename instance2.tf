variable "project" {}

variable "credentils_file" {}
variable "region" {
  default = "us-central1"  
}
variable "zone" {
  default = "us-central1-c"
}
variable "cidrs" {
  default = {} //type=list
}



provider "google" {
    //for this crednetials file, we need to provide the json key file
    //for the service account created specifically for the terraform 

    credentials = file(var.credentils_file)
    project = var.project
    region = var.region
    zone = var.zone
}

resource "google_compute_network" "vpc_network" {
    name = "terrafom-network"  
}

resource "google_compute_address" "vm_static_ip" {
    name = "terraform-static-ip"
  
}

resource "google_compute_instance" "vm_instance" {
    name = "terraform-instance"
    machine_type = "f1-micro"
    tags = ["web", "dev"]

    boot_disk{
        initialize_params{
            image = "debian-cloud/debian-9"
        }
    network_interface{
        network = module.network.network_name
        subnetwork = module.network.subnet_names[0]
        access_config{
           //associting the static ip address with the 
           //virtual machine instance 
           nat_ip = google_compute_address.vm_static_ip.address
        }
    }
    }
}

resource "google_compute_instance" "vm_instance2" {
    name = "terraform-instance2"
    machine_type = "f1-micro"
    tags  = ["web", "dev"]

    provisioner "local-exec"{
        command = "echo ${google_compute_instance.vm_instance2.name : google_compute_instance.vm_instance2.network_interface[0].access_config[0].nat_ip} >> ipaddress.txt"
    }
    
  
}

module "network" {
  source = "terraform-google-modules/network/google"
  version = "1.1.0"

  network_name = "terraform-vpc-network"
  project_id = var.project

  subnets[{
      subnet_name = "subnet-01"
      subnet_ip = var.cidrs[0]
      subnet_region = var.region
  },
  {
      subnet_name = "subnet-02"
      subnet_ip = var.cidrs[1]
      subnet_region = var.region

      subnet_private_access = "true"
  },
  ]

  secondary_ranges = {
      subnet-01 = []
      subnet-02 = []
       
  }
}

output "vpc_network_subnet_ips" {
  value = module.network.vpc_network_subnet_ips
}


//storing the state at the backend:

terraform{
    backend "remote"{
        organization = "ORG NAME"

        workspaces{
            name = "Example-Workspaces"
        }
    
    }
}





