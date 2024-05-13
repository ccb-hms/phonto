
## Search functions

nhanesSearchTableNames("DEMO")

nhanesSearchTableNames("DEMO", details = TRUE)

nhanesSearchVarName("DMDEDUC3", namesonly = FALSE) |> str()

nhanesSearchVarName("AUXRR103")

nhanesSearch("pressure") |> str()

nhanesTableSummary("AUXAR_D")

## TODO
## nhanesTableVars
## nhanesTables


