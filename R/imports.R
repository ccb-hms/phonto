
# import internal functions from nhanesA may used in the other functions in phonto package
.checkTableNames <- utils::getFromNamespace(".checkTableNames", "nhanesA")
.convertTranslatedTable <- utils::getFromNamespace(".convertTranslatedTable", "nhanesA")
.nhanesQuery <- utils::getFromNamespace(".nhanesQuery", "nhanesA")
cn = utils::getFromNamespace("cn", "nhanesA")
MetadataTable = utils::getFromNamespace("MetadataTable", "nhanesA")
RawTable = utils::getFromNamespace("RawTable", "nhanesA")
TranslatedTable = utils::getFromNamespace("TranslatedTable", "nhanesA")
