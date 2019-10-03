structure tigerseman :> tigerseman =
struct

open tigerabs
open tigersres
open tigertrans

type expty = {exp: unit, ty: Tipo}

type venv = (string, EnvEntry) tigertab.Tabla
type tenv = (string, Tipo) tigertab.Tabla

val tab_tipos : (string, Tipo) Tabla = tabInserList(
	tabNueva(),
	[("int", TInt RW), ("string", TString)])

(*Modificamos la pila para almacenar los nombres de las funciones*)
val namePila: string  tigerpila.Pila = tigerpila.nuevaPila()
fun pushName l = tigerpila.pushPila namePila l
fun popName() = tigerpila.popPila namePila
fun topName() = tigerpila.topPila namePila


fun searchLevel()



val tab_vars : (string, EnvEntry) Tabla = tabInserList(
	tabNueva(),
	[("print", Func{level=topLevel(), label="print",
		formals=[TString], result=TUnit, extern=true}),
	("flush", Func{level=topLevel(), label="flush",
		formals=[], result=TUnit, extern=true}),
	("getchar", Func{level=topLevel(), label="getstr",
		formals=[], result=TString, extern=true}),
	("ord", Func{level=topLevel(), label="ord",
		formals=[TString], result=TInt RW, extern=true}),
	("chr", Func{level=topLevel(), label="chr",
		formals=[TInt RW], result=TString, extern=true}),
	("size", Func{level=topLevel(), label="size",
		formals=[TString], result=TInt RW, extern=true}),
	("substring", Func{level=topLevel(), label="substring",
		formals=[TString, TInt RW, TInt RW], result=TString, extern=true}),
	("concat", Func{level=topLevel(), label="concat",
		formals=[TString, TString], result=TString, extern=true}),
	("not", Func{level=topLevel(), label="not",
		formals=[TInt RW], result=TInt RW, extern=true}),
	("exit", Func{level=topLevel(), label="exit",
		formals=[TInt RW], result=TUnit, extern=true})
	])

fun tipoReal (TTipo (s, ref (SOME (t)))) = tipoReal t
  | tipoReal t = t

fun tiposIguales (TRecord _) TNil = true
  | tiposIguales TNil (TRecord _) = true
  | tiposIguales (TRecord (_, u1)) (TRecord (_, u2 )) = (u1=u2)
  | tiposIguales (TArray (_, u1)) (TArray (_, u2)) = (u1=u2)
  | tiposIguales (TInt _) (TInt _) = true
  | tiposIguales (TTipo (_, r)) b =
		let
			val a = case !r of
				SOME t => t
				| NONE => raise Fail "No debería pasar! (1)"
		in
			tiposIguales a b
		end
  | tiposIguales a (TTipo (_, r)) =
		let
			val b = case !r of
				SOME t => t
				| NONE => raise Fail "No debería pasar! (2)"
		in
			tiposIguales a b
		end
  | tiposIguales a b = (a=b)


(*Agregamos*)
  fun tiposIgualesList ([],[]) = true
      | tiposIgualesList (x::xs,y::ys) = (tiposIguales x y) andalso tiposIgualesList (xs,ys)
      | tiposIgualesList (x::xs,[]) = false
      | tiposIgualesList ([],y::ys) = false

(*Agregamos*)
  fun searchList([],_) = NONE
      | searchList((s2,x)::xs,s) = if s = s2 then SOME x
  	                             else searchList (xs,s)



(*Agregamos*)
  fun zip [] _  = []
      | zip _ [] = []
      | zip (x::xs) (y::ys) = ((x,y)::(zip xs ys))


(*Agregamos*)
  fun checkDuplicates ys = let fun aux  rs [] = NONE
                                | aux rs ((h:string*int)::hs) = (case List.find (fn x => x = #1 h) rs of
  															                                    NONE => aux ((#1 h)::rs) hs
  																										            | SOME_ => SOME h)
  												 in aux [] ys
  												 end








fun transExp(venv, tenv) =
	let fun error(s, p) = raise Fail ("Error -- línea "^Int.toString(p)^": "^s^"\n")
		fun msg1(f) = "Los tipos de los argumentos de " ^ f ^ " no coinciden con los tipos de sus parámetros"
		fun msg2(f) = f ^ " no es una función"
		fun msg3(f) = f ^ " no está definida"
		val msg4 = "El tipo de la variable no coincide con el de la expresión"
		fun msg5(v) = v ^ " no es una variable"
		fun msg6(v) = "El tipo " ^ v ^ " no está definido"
		val msg7 = "El tipo del array no coincide con el de la expresión de inicialización"
		val msg8 = "El tamaño debe tener tipo entero"
		fun msg9(s) = s ^ " no es un arreglo"
		val msg10 = "Los límites del for deben ser enteros"
		val msg11 = "No puede haber una asignación a una variable de solo lectura"
		fun msg12(s) = s ^ " ya está declarada en el batch"
		fun trexp(VarExp v) = trvar(v)
		| trexp(UnitExp _) = {exp=unitExp(), ty=TUnit}
		| trexp(NilExp _)= {exp=nilExp(), ty=TNil}
		| trexp(IntExp(i, _)) = {exp=intExp i, ty=TInt RW}
		| trexp(StringExp(s, _)) = {exp=stringExp(s), ty=TString}
		(*Agregamos*)
		| trexp(CallExp({func, args}, nl)) = (case tabBusca(func,venv) of
                                               SOME (Func reg) => let val t1 = map trexp args
                                                                      val t2 = map (fn x => #ty x) t1
														              val formals = #formals reg
                                               in if length t2 = length formals then if tiposIgualesList (t2,#formals reg) then {exp=SCAF, ty= #result reg}
                                                                                     else error (msg1(func),nl)
												   else error("La cantidad de argumentos no coincide con la cantidad de parámetros",nl)
                                                                 end
                                              |SOME _  => error (msg2(func),nl)
                                              |NONE => error (msg3(func),nl))


		| trexp(OpExp({left, oper=EqOp, right}, nl)) =
			let
				val {exp=expl, ty=tyl} = trexp left
				val {exp=expr, ty=tyr} = trexp right
			in
				if tiposIguales tyl tyr andalso not (tyl=TNil andalso tyr=TNil) andalso tyl<>TUnit then
					{exp=if tiposIguales tyl TString then binOpStrExp {left=expl,oper=EqOp,right=expr} else binOpIntRelExp {left=expl,oper=EqOp,right=expr}, ty=TInt RW}
					else error("Tipos no comparables", nl)
			end
		| trexp(OpExp({left, oper=NeqOp, right}, nl)) =
			let
				val {exp=expl, ty=tyl} = trexp left
				val {exp=expr, ty=tyr} = trexp right
			in
				if tiposIguales tyl tyr andalso not (tyl=TNil andalso tyr=TNil) andalso tyl<>TUnit then
					{exp=if tiposIguales tyl TString then binOpStrExp {left=expl,oper=NeqOp,right=expr} else binOpIntRelExp {left=expl,oper=NeqOp,right=expr}, ty=TInt RW}
					else error("Tipos no comparables", nl)
			end
		| trexp(OpExp({left, oper, right}, nl)) =
			let
				val {exp=expl, ty=tyl} = trexp left
				val {exp=expr, ty=tyr} = trexp right
			in
				if tiposIguales tyl tyr then
					case oper of
						PlusOp => if tipoReal tyl=TInt RW then {exp=binOpIntExp {left=expl, oper=oper, right=expr},ty=TInt RW} else error("Error de tipos", nl)
						| MinusOp => if tipoReal tyl=TInt RW then {exp=binOpIntExp {left=expl, oper=oper, right=expr},ty=TInt RW} else error("Error de tipos", nl)
						| TimesOp => if tipoReal tyl=TInt RW then {exp=binOpIntExp {left=expl, oper=oper, right=expr},ty=TInt RW} else error("Error de tipos", nl)
						| DivideOp => if tipoReal tyl=TInt RW then {exp=binOpIntExp {left=expl, oper=oper, right=expr},ty=TInt RW} else error("Error de tipos", nl)
						| LtOp => if tipoReal tyl=TInt RW orelse tipoReal tyl=TString then
							{exp=if tipoReal tyl=TInt RW then binOpIntRelExp {left=expl,oper=oper,right=expr} else binOpStrExp {left=expl,oper=oper,right=expr},ty=TInt RW}
							else error("Error de tipos", nl)
						| LeOp => if tipoReal tyl=TInt RW orelse tipoReal tyl=TString then
							{exp=if tipoReal tyl=TInt RW then binOpIntRelExp {left=expl,oper=oper,right=expr} else binOpStrExp {left=expl,oper=oper,right=expr},ty=TInt RW}
							else error("Error de tipos", nl)
						| GtOp => if tipoReal tyl=TInt RW orelse tipoReal tyl=TString then
							{exp=if tipoReal tyl=TInt RW then binOpIntRelExp {left=expl,oper=oper,right=expr} else binOpStrExp {left=expl,oper=oper,right=expr},ty=TInt RW}
							else error("Error de tipos", nl)
						| GeOp => if tipoReal tyl=TInt RW orelse tipoReal tyl=TString then
							{exp=if tipoReal tyl=TInt RW then binOpIntRelExp {left=expl,oper=oper,right=expr} else binOpStrExp {left=expl,oper=oper,right=expr},ty=TInt RW}
							else error("Error de tipos", nl)
						| _ => raise Fail "No debería pasar! (3)"
				else error("Error de tipos", nl)
			end
		| trexp(RecordExp({fields, typ}, nl)) =
			let
				(* Traducir cada expresión de fields *)
				val tfields = map (fn (sy,ex) => (sy, trexp ex)) fields

				(* Buscar el tipo *)
				val (tyr, cs) = case tabBusca(typ, tenv) of
					SOME t => (case tipoReal t of
						TRecord (cs, u) => (TRecord (cs, u), cs)
						| _ => error(typ^" no es de tipo record", nl))
					| NONE => error("Tipo inexistente ("^typ^")", nl)

				(* Verificar que cada campo esté en orden y tenga una expresión del tipo que corresponde *)
				fun verificar _ [] [] = []
				  | verificar _ (c::cs) [] = error("Faltan campos", nl)
				  | verificar _ [] (c::cs) = error("Sobran campos", nl)
				  | verificar n ((s,t,_)::cs) ((sy,{exp,ty})::ds) =
						if s<>sy then error("Error de campo", nl)
						else if tiposIguales ty t then (exp, n)::(verificar (n+1) cs ds)
							 else error("Error de tipo del campo "^s, nl)
				val lf = verificar 0 cs tfields
			in
				{exp=recordExp lf, ty=tyr}
			end
		| trexp(SeqExp(s, nl)) =
			let	val lexti = map trexp s
				val exprs = map (fn{exp, ty} => exp) lexti
				val {exp, ty=tipo} = hd(rev lexti)
			in	{ exp=seqExp (exprs), ty=tipo } end

         (*Agregamos*)
		| trexp(AssignExp({var, exp}, nl)) = let val {ty=res,...} = trvar(var,nl)
		                                     in (case res of
											    (TInt RO) => error(msg11,nl)
												  | t => let val {ty=t2,...} = (transExp (venv,tenv)) exp
											           in if tiposIguales t t2 then  {exp=SCAF, ty=TUnit}
												            else error(msg4,nl)
														 end)
											 end

		| trexp(IfExp({test, then', else'=SOME else'}, nl)) =
			let val {exp=testexp, ty=tytest} = trexp test
			    val {exp=thenexp, ty=tythen} = trexp then'
			    val {exp=elseexp, ty=tyelse} = trexp else'
			in
				if tipoReal tytest=TInt RW andalso tiposIguales tythen tyelse then
				{exp=if tipoReal tythen=TUnit then ifThenElseExpUnit {test=testexp,then'=thenexp,else'=elseexp} else ifThenElseExp {test=testexp,then'=thenexp,else'=elseexp}, ty=tythen}
				else error("Error de tipos en if" ,nl)
			end
		| trexp(IfExp({test, then', else'=NONE}, nl)) =
			let val {exp=exptest,ty=tytest} = trexp test
			    val {exp=expthen,ty=tythen} = trexp then'
			in
				if tipoReal tytest=TInt RW andalso tythen=TUnit then
				{exp=ifThenExp{test=exptest, then'=expthen}, ty=TUnit}
				else error("Error de tipos en if", nl)
			end
		| trexp(WhileExp({test, body}, nl)) =
			let
				val ttest = trexp test
				val tbody = trexp body
			in
				if tipoReal (#ty ttest) = TInt RW andalso #ty tbody = TUnit then {exp=whileExp {test=(#exp ttest), body=(#exp tbody), lev=topLevel()}, ty=TUnit}
				else if tipoReal (#ty ttest) <> TInt RW then error("Error de tipo en la condición", nl)
				else error("El cuerpo de un while no puede devolver un valor", nl)
			end
		(*Agregamos*)
		| trexp(ForExp({var, escape, lo, hi, body}, nl)) =
				let  val {exp=explo,ty=tylo} = trexp lo
					 val {exp=exphi,ty=tyhi} = trexp hi
				in if (tiposIguales tylo (TInt RO)) andalso (tiposIguales tyhi (TInt RO))
				   then  let val name = topName()
				             val frame = (case tabBusca(name,venv) of
							               SOME (Func f) => #frame (#level f)
										  | _ => raise Fail "Esto no debería pasar")
				             val access' = allocLocal (frame) (!escape)
				             val venv' = tabInserta(var,Var {ty=TInt RO, level = getActualLev(), access = access' },venv)
							 val {exp=expbody,ty=tybody} = (transExp (venv',tenv)) body
						in {exp=SCAF,ty=TUnit}
						 end
				 else error(msg10,nl)
				end

		| trexp(LetExp({decs, body}, _)) =
			let
				fun aux (d, (v, t, exps1)) =
				let
					val (v', t', exps2) = trdec (v, t) d
				in
					(v', t', exps1@exps2)
				end
				val (venv', tenv', expdecs) = List.foldl aux (venv, tenv, []) decs
				val {exp=expbody,ty=tybody}=transExp (venv', tenv') body
			in
				{exp=seqExp(expdecs@[expbody]), ty=tybody}
			end
		| trexp(BreakExp nl) = {exp=SCAF, ty=TUnit}
		(*Agregamos todo lo que sigue*)
		| trexp(ArrayExp({typ, size, init}, nl)) = (case tabBusca(typ,tenv) of
		                                             NONE => error(msg6(typ),nl)
													| SOME (TArray (t,_)) => let val {ty=t2,...} = trexp init
																             in if tiposIguales (!t) t2 then let val {ty=ts,...} = trexp size
																						                     in if tiposIguales ts (TInt RW) then {exp=SCAF, ty=TUnit}
																											    else error(msg8,nl)
																											 end
																				else error(msg7,nl)
																			 end
												    | SOME _ => error(msg9(typ),nl))

		and trvar(SimpleVar s, nl) = (case tabBusca(s,venv) of
		                              NONE => error(msg3(s),nl)
									  | SOME (Var {ty=t}) => {exp=SCAF,ty=t}
									  | SOME _ => error(s ^ "no es una variable simple",nl))


		| trvar(FieldVar(v, s), nl) = (case trvar(v,nl) of
		                                {ty=(TRecord (tyl,_)),...} => let val tyl2 = map (fn (x,y,_) => (x,y)) tyl
		                                                              in (case searchList(tyl2,s) of
									                                       NONE => error(msg3(s),nl)
										                                   |SOME typ  => {exp = SCAF,ty=(!typ)})
								                                       end
								        |_ => error(s ^ " no es campo de un record definido",nl))

		| trvar(SubscriptVar(v, e), nl) = (case trvar(v,nl) of
		                                 {ty=TArray (typ,_),...} => let val {ty=t,...} = trexp e
										                            in if tiposIguales t (TInt RW) then {exp=SCAF,ty=(!typ)}
																       else error("La expresion no es de into int",nl)
																    end
										 |_ => error("La variable no es de tipo Array",nl))

		and trdec (venv, tenv) (VarDec ({name,escape,typ=NONE,init},pos)) =
		                                   let val {ty=t,...} = (transExp (venv,tenv)) init
										   in if tiposIguales t TNil then error("Nil no puede ser asignado en variables que no tenga un tipo record",pos)
										      else let val venv' = tabRInserta(name,Var {ty=t},venv)
												   in (venv',tenv,[])
												   end
										   end

		| trdec (venv,tenv) (VarDec ({name,escape,typ=SOME s,init},pos)) = let val {ty=t,...} = transExp (venv,tenv) init
		                                                                   in (case tabBusca(s,tenv) of
																		        NONE => error("El tipo " ^ s ^ " no existe",pos)
																				|SOME t2 => if t = t2 then let val venv' = tabRInserta(name,Var {ty=t},venv)
																		                                   in (venv',tenv,[])
																			    			               end

																		                     else error("El tipo de la variable es " ^ s ^ " y no coincide con el de la expresion",pos))
																		   end

		| trdec (venv,tenv) (FunctionDec fs) =  let val np = map (fn (reg,pos) => (#name reg,pos)) fs
		                                        in (case checkDuplicates np of
														NONE => let  val funList  = map (trfun tenv) fs
																	 val names = map (fn (n,_) => n) np
																     val funcsEntry = zip names funList
																     val venv' = List.foldl (fn ((s,f),e) => tabRInserta(s,f,e)) venv funcsEntry
																	 val _ = map (fn (r,nl) => trexpBody r venv' tenv nl) fs
																 in (venv',tenv,[])
																end
														|SOME (f,p) => error(msg12(f),p))
												end

		| trdec (venv,tenv) (TypeDec ts) = let val np = map (fn (r,p) => (#name r,p)) ts
		                                   in (case checkDuplicates np of
																			     SOME (n,p) => error(msg12(n),p)
																			     | NONE => let val ts' = map (fn (r,_) => r) ts
																					           in (venv,fijaTipos ts' tenv,[])
																							       end)
		         	                         end


		and   trfun tenv  dec = let  val (r,nl) = dec
		                             val (prueba : Tipo list) = map (trparam nl tenv) (#params r)
		                        in (case  #result r of
									                NONE => Func {level = mainLevel, label = #name r,formals = prueba, result = TUnit, extern = false}
							                   | SOME s => (case tabBusca(s,tenv) of
								                               NONE => error(s ^" no es un tipo",nl)
					   						                       |SOME t  => Func {level = mainLevel, label = #name r,formals = prueba, result = t, extern = false} ))
		                        end


  and trparam nl tenv p = (case #typ p  of
		 			  								NameTy s => (case tabBusca(s,tenv) of
		 				     						               NONE => error(s^ " no es un tipo",nl)
		 					  									        |SOME t => t)
		 						   		      |_ => error("No es un NameTy",nl))

  and trexpBody r venv tenv nl = let val name = #name r
                                     val _ = pushName name (*Agregamos el nombre a la pila para poder acceder a su frame*)
			                         val nameParams = map #name (#params r)
         						     val typsParams = (case tabBusca(name,venv) of
					    					                     NONE => raise Fail "Basura"
							    								 |SOME (Func f) => #formals f
										    					 | SOME _ => raise Fail "Basura")
								     val ntParams = zip nameParams typsParams
									 val venv' = List.foldl (fn ((s,t),v) => tabRInserta(s,Var {ty=t},v)) venv ntParams
									 val res = (transExp (venv',tenv)) (#body r)
									 val _ = popName() (*Ya analizamos el cuerpo asi que descartamos el nombre*)
                                     val tyRes = #ty res
						    in (case #result r of
							    NONE => if tiposIguales tyRes TUnit then res
								        else error(name ^ " es un procedimiento y no puede retornar un valor",nl)
							    |SOME s => (case tabBusca(s,tenv) of
								             NONE => error("El tipo del valor de retorno de " ^ name ^ " no es válido",nl)
											 |SOME t => if tiposIguales t tyRes then res
											           else error("El valor de retorno de " ^name^ " debe se de tipo " ^ s,nl ) ))
						    end



	in trexp end
fun transProg ex =
	let	val main =
				LetExp({decs=[FunctionDec[({name="_tigermain", params=[],
								result=NONE, body=ex}, 0)]],
						body=UnitExp 0}, 0)
		val _ = transExp(tab_vars, tab_tipos) main
	in	print "bien!\n" end
end