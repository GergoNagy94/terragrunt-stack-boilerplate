unit "vpc" {
  #vpc placeholder
}

unit "core_sg" {
  #core sg placeholder
}

{{ if or (eq .InfrastructurePreset "webapp") (eq .InfrastructurePreset "eks") }}
unit "web_sg" {
  #web sg placeholder
}
{{ end }}

{{ if eq .InfrastructurePreset "webapp" }}
unit "app_sg" {
  #app sg placeholder
}

unit "db_sg" {
#db sg placeholder
}
{{ end }}

{{ if eq .InfrastructurePreset "eks" }}
unit "eks_cluster_sg" {
  #eks sg placeholder
}

unit "eks_node_sg" {
  #eks node sg placeholder
}
{{ end }}