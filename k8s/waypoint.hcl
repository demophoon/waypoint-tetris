project = "nginx-project"

# Labels can be specified for organizational purposes.
# labels = { "foo" = "bar" }

variable "tag" {
  default     = "latest"
  type        = string
  description = "The tab for the built image in the Docker registry."
}

variable "image" {
  default     = "tetris"
  type        = string
  description = "Image name for the built image in the Docker registry."
}

variable "registry_local" {
  default     = true
  type        = bool
  description = "Whether or not to push the built container to a remote registry"
}

variable "release_port" {
  default     = "3000"
  type        = string
  description = "Port to open for the releaser."
}

app "tetris" {
  build {
    use "docker" {
    }
    registry {
      use "docker" {
        image = var.image
        tag   = var.tag
        local = var.registry_local
      }
    }

  }

  deploy {
    use "kubernetes" {
      probe_path = "/"
    }
  }

  release {
    use "kubernetes" {
      load_balancer = true
      port          = var.release_port
    }
  }
}
