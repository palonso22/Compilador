structure tigersres =
struct

open tigerabs
open tigertab
open tigertips

datatype EnvEntry =
	VIntro	(* int readonly *)
	| Var of {ty: Tipo}
	| Func of {level: unit, label: tigertemp.label, (*level le damos mainLevel por ahora y label un string*)
		formals: Tipo list, result: Tipo, extern: bool}

val mainLevel = ()
end
