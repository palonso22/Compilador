open tigerlex
open tigergrm
open tigerescap
open tigerseman
open tigerframe
open tigercanon
open tigerinterp
open BasicIO Nonstdio

fun canonizar stm = let val lin = tigercanon.linearize stm
                        val basics = tigercanon.basicBlocks lin
										in tigercanon.traceSchedule basics
										end


fun lexstream(is: instream) =
	Lexing.createLexer(fn b => fn n => buff_input is b 0 n);
fun errParsing(lbuf) = (print("Error en parsing!("
	^(makestring(!num_linea))^
	")["^(Lexing.getLexeme lbuf)^"]\n"); raise Fail "fin!")
fun main(args) =
	let	fun arg(l, s) =
			(List.exists (fn x => x=s) l, List.filter (fn x => x<>s) l)
		val (arbol, l1)		= arg(args, "-arbol")
		val (escapes, l2)	= arg(l1, "-escapes")
		val (ir, l3)		= arg(l2, "-ir")
		val (canon, l4)		= arg(l3, "-canon")
		val (code, l5)		= arg(l4, "-code")
		val (flow, l6)		= arg(l5, "-flow")
		val (inter, l7)		= arg(l6, "-inter")
		val entrada =   (case l7 of
										[n] => ((open_in n) handle _ => raise Fail (n^" no existe!"))
										| [] => std_in
										| _ => raise Fail "opcio'n dsconocida!")
		val lexbuf = lexstream entrada
		val expr = prog Tok lexbuf handle _ => errParsing lexbuf
		val _ = findEscape(expr)
		val _ = if arbol then tigerpp.exprAst expr else ()
		val _ = if arbol then tigerpp.exprAst expr else ()
		val _  = transProg(expr)
		val frags = tigertrans.getResult()
		val (funFrags,stringFrags) = List.partition tigerframe.isProc frags
		val funFrags' = map (fn a => let val x = tigerframe.unProc a in (#body x, #frame x) end) funFrags
		val stringFrags' = map (fn a => tigerframe.unString a)  stringFrags
		val canonFunFrags = map (fn (x,y) => (canonizar x,y)) funFrags'
	in
    (tigerinterp.inter false canonFunFrags stringFrags';
		print "yes!!\n")
	end	handle Fail s => print("Fail: "^s^"\n")

val _ = main(CommandLine.arguments())
