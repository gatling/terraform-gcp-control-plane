provider "google" {
  project = "<ProjectId>"
  region  = "<Region>"
}

# Create a control plane based on GCP VM
# Reference: https://docs.gatling.io/reference/install/cloud/private-locations/gcp/installation/
module "control-plane" {
  source            = "gatling/control-plane/gcp"
  name              = "<Name>"
  description       = "My GCP control plane description"
  token-secret-name = "<TokenSecretName>"
  # service-account-name = "<ServiceAccountName>" # Optional, defaults to name
  network = {
    zone    = "<Zone>"
    network = "<Network>"
    # subnetwork         = "<SubNetwork>"
    # enable-external-ip = true
  }

  # Configure GCP private locations
  # Reference: https://docs.gatling.io/reference/install/cloud/private-locations/gcp/configuration/#control-plane-configuration-file
  locations = [
    {
      id          = "prl_gcp"
      description = "Private Location on GCP"
      project     = "<ProjectId>"
      zone        = "<Zone>"
      machine = {
        #   type        = "c3-highcpu-4"
        #   preemptible = false
        #   engine      = "classic"
        #   image = {
        #     type    = "certified"
        #     java    = "latest"
        #     project = "<ProjectName>"
        #     family  = "<ImageFamily>"
        #     id      = "<ImageId>"
        #   }
        #   disk = {
        #     sizeGb = 20
        #   }
        #   network-interface = {
        #     project          = "<NetworkInterfaceProjectName>"
        #     network          = "<Network>"
        #     subnetwork       = "<SubNetwork>"
        #     with-external-ip = true
        #   }
      }
      # instance-template = "<InstanceTemplate>"
      # system-properties = {}
      # java-home         = "/usr/lib/jvm/zulu"
      # jvm-options       = ["-Xmx4G", "-Xms512M"]
      # enterprise-cloud = {
      #   Setup the proxy configuration for the private location
      #   Reference: https://docs.gatling.io/reference/install/cloud/private-locations/network/#configuring-a-proxy
      # }
    }
  ]

  # Configure a private package (control plane repository & server) based on GCS (optional)
  # Reference: https://docs.gatling.io/reference/install/cloud/private-locations/private-packages/#gcp-cloud-storage
  # Reference: https://docs.gatling.io/reference/install/cloud/private-locations/private-packages/#control-plane-server
  # private-package = {
  #   project = "<ProjectId>"
  #   bucket  = "<BucketName>"
  #   path    = ""
  #   upload = {
  #     directory = "/tmp"
  #   }
  # }

  # container = {
  #   image       = "gatlingcorp/control-plane:latest"
  #   command     = []
  #   environment = []
  # }
  # # Configure git credentials for the control plane. Requires builder image: "gatlingcorp/control-plane:latest-builder"
  # # Reference: https://docs.gatling.io/reference/execute/cloud/user/build-from-sources/
  # git = {
  #   credentials = {
  #     username          = "<GitUsername>"
  #     token-secret-name = "<GitTokenSecretName>"
  #   }
  #   ssh = {
  #     secret-name = "<GitSshSecretName>"
  #     file-name   = "<FileName>"
  #   }
  #   cache = {
  #     paths = ["/app/.m2", "/app/.gradle", "/app/.sbt", "/app/.npm"]
  #   }
  # }
  # compute = {
  #   boot-disk-image            = "projects/cos-cloud/global/images/cos-stable-113-18244-85-49"
  #   machine-type               = "e2-standard-2"
  #   min-cpu-platform           = "<MinCpuPlatform>"
  #   confidential-instance-type = "ConfidentialInstanceType"
  #   shielded = {
  #     enable-secure-boot          = true
  #     enable-vtpm                 = true
  #     enable-integrity-monitoring = true
  #   }
  #   confidential = {
  #     enable        = false
  #     instance-type = "e2-standard-2"
  #   }
  # }
  # enterprise-cloud = {
  #   Setup the proxy configuration for the private location
  #   Reference: https://docs.gatling.io/reference/install/cloud/private-locations/network/#configuring-a-proxy
  # }
  # server = {
  #   port        = 8080
  #   bindAddress = "0.0.0.0"
  #   certificate = {
  #     path     = "/path/to/certificate.p12"
  #     password = "password"
  #   }
  # }
}
