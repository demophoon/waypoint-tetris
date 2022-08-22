project = "k8s-tetris"

pipeline "marathon" {
  step "up" {
    #image_url = "localhost:5000/waypoint-odr:dev"

    use "up" {
    }
  }

  step "do-it" {
    image_url = "localhost:5000/waypoint-odr:dev"

    use "exec" {
      command = "echo"
      args    = ["this works!"]
    }
  }

  step "broken?" {
    pipeline "exec" {
      step "build" {
        use "build" {
        }
      }
    }
  }
}

pipeline "simple-nested" {
  step "build" {
    use "build" {
    }
  }

  step "deploy" {
    pipeline "deploy" {
      step "deploy" {
        use "deploy" {
        }
      }
    }
  }
}

pipeline "release" {
  step "build" {
    use "build" {
    }
  }

  step "test" {
    pipeline "test" {
      step "scan-then-sign" {
        image_url = "localhost:5000/waypoint-odr:dev"

        use "exec" {
          command = "echo"
          args    = ["singing some artifacts!!"]
        }
      }

      step "deploy-test" {
        use "deploy" {
        }
      }

      step "healthz" {
        image_url = "localhost:5000/waypoint-odr:dev"

        use "exec" {
          command = "curl"
          args    = ["-v", "example.com"]
        }
      }
    }
  }

  step "production" {
    pipeline "prod" {
      step "build" {
        use "build" {
          // actually use docker-pull here
        }
      }

      step "deploy-prod" {
        use "deploy" {
        }
      }

      step "healthz" {
        image_url = "localhost:5000/waypoint-odr:dev"

        use "exec" {
          command = "curl"
          args    = ["-v", "example.com"]
        }
      }

      step "release-prod" {
        use "release" {
        }
      }
    }
  }

  step "notify-release" {
    image_url = "localhost:5000/waypoint-odr:dev"

    use "exec" {
      command = "echo"
      args    = ["we released the app!!"]
    }
  }

}

runner {
  profile = "kubernetes-bootstrap-profile"

  enabled = true

  data_source "git" {
    url  = "https://github.com/briancain/waypoint-tetris.git"
    path = ""
  }
}

app "tetris" {
  build {
    use "docker" {
    }
    workspace "production" {
      use "docker-pull" {
        image = var.image
        tag   = var.tag
      }
    }

    registry {
      use "docker" {
        image    = var.image
        tag      = var.tag
        username = var.registry_username
        password = var.registry_password
        local    = var.registry_local
      }
    }
  }

  deploy {
    use "kubernetes" {
      probe_path   = "/"
      image_secret = var.regcred_secret

      cpu {
        request = "250m"
        limit   = "500m"
      }

      memory {
        request = "64Mi"
        limit   = "128Mi"
      }

      autoscale {
        min_replicas = 2
        max_replicas = 5
        cpu_percent  = 50
      }
    }
  }

  release {
    use "kubernetes" {
      load_balancer = true
      port          = 3000
    }
  }
}

variable "image" {
  # free tier, old container registry
  #default     = "bcain.jfrog.io/default-docker-virtual/tetris"
  default     = "team-waypoint-dev-docker-local.artifactory.hashicorp.engineering/tetris"
  type        = string
  description = "Image name for the built image in the Docker registry."
}

variable "tag" {
  default     = "latest"
  type        = string
  description = "Image tag for the image"
}

variable "registry_local" {
  default     = false
  type        = bool
  description = "Set to enable local or remote container registry pushing"
}

variable "registry_username" {
  default = dynamic("vault", {
    path = "secret/data/registry"
    key  = "/data/registry_username"
  })
  type        = string
  sensitive   = true
  description = "username for container registry"
}

variable "registry_password" {
  default = dynamic("vault", {
    path = "secret/data/registry"
    key  = "/data/registry_password"
  })
  type        = string
  sensitive   = true
  description = "password for registry" // don't hack me plz
}

variable "regcred_secret" {
  default     = "regcred"
  type        = string
  description = "The existing secret name inside Kubernetes for authenticating to the container registry"
}
