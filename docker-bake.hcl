group "default" {
	targets = ["mariadb", "mysql", "postgres-15", "postgres-14", "postgres-13", "postgres-12"]
}

group "postgres" {
	targets = ["postgres-16", "postgres-15", "postgres-14", "postgres-13", "postgres-12"]
}

target "common" {
	platforms = ["linux/amd64", "linux/arm64/v8", "linux/ppc64le", "linux/s390x"]
}

target "mariadb" {
	inherits = ["common"]
	target = "mariadb"
	tags = [
		"paolobasso/database_dumper:mariadb",
	]
}

target "mysql" {
	inherits = ["common"]
	target = "mysql"
	tags = [
		"paolobasso/database_dumper:mysql",
	]
}

target "postgres-16" {
	inherits = ["common"]
	target = "postgres-16"
	tags = [
		"paolobasso/database_dumper:postgres-16",
	]
}

target "postgres-15" {
	inherits = ["common"]
	target = "postgres-15"
	tags = [
		"paolobasso/database_dumper:postgres-15",
	]
}

target "postgres-14" {
	inherits = ["common"]
	target = "postgres-14"
	tags = [
		"paolobasso/database_dumper:postgres-14",
	]
}

target "postgres-13" {
	inherits = ["common"]
	target = "postgres-13"
	tags = [
		"paolobasso/database_dumper:postgres-13",
	]
}

target "postgres-12" {
	inherits = ["common"]
	target = "postgres-12"
	tags = [
		"paolobasso/database_dumper:postgres-12",
	]
}

