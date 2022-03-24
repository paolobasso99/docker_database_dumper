group "default" {
	targets = ["latest"]
}

target "common" {
	platforms = ["linux/amd64", "linux/arm64/v8", "linux/ppc64le", "linux/s390x"]
}

target "latest" {
	inherits = ["common"]
	tags = [
		"paolobasso/database_dumper:latest"
	]
}

