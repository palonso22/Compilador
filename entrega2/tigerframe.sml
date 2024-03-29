(*
	Frames para el 80386 (sin displays ni registers).

		|    argn    |	fp+4*(n+1)
		|    ...     |
		|    arg2    |	fp+16
		|    arg1    |	fp+12
		|  fp level  |  fp+8
		|  retorno   |	fp+4
		|   fp ant   |	fp
		--------------	fp
		|   local1   |	fp-4
		|   local2   |	fp-8
		|    ...     |
		|   localn   |	fp-4*n
*)

structure tigerframe :> tigerframe = struct

open tigertree

datatype access = InFrame of int | InReg of tigertemp.label

type frame = {
	name: string,
	accesses: access list,
	formals: bool list,
	locals: bool list,
	actualLocal: int ref
}
type register = string


datatype frag = PROC of {body: tigertree.stm, frame: frame}
	| STRING of tigertemp.label * string

fun isProc (PROC _ ) = true
  | isProc _ = false

fun unProc (PROC x) = x
    | unProc _ =  raise Fail "No deberia pasar\n"
fun unString (STRING x) = x
    | unString _ = raise Fail "No deberia pasar\n"


val rv = "RV"				(* return value  *)
val ov = "OV"				(* overflow value (edx en el 386) *)
val fp = "FP"				(* frame pointer *)
val sp = "SP"				(* stack pointer *)

val fpPrev = 0				(* offset (bytes) *)
val fpPrevLev = 8			(* offset (bytes) *)
val wSz = 4				(* word size in bytes *)
val log2WSz = 2				(* base two logarithm of word size in bytes *)
val calldefs = [rv]
val callersaves = []
val calleesaves = []

val localsInicial = 0			(* words *)
val localsGap = ~4 			(* bytes *)
val specialregs = [rv, fp, sp]
val argregs = []

fun setFrame accessList (f:frame) = {name=(#name f), accesses=accessList, formals=(#formals f), locals=(#locals f), actualLocal=(#actualLocal f)}

fun newFrame{name, formals} = {
	name=name,
	accesses=[],
	formals=formals,
	locals=[],
	actualLocal=ref localsInicial
}

fun name(f: frame) = #name f

fun allocLocal (f: frame) b =
	case b of
	  true =>
		let
			val ret = InFrame(!(#actualLocal f)*wSz+localsGap)
			val _ = #actualLocal f:=(!(#actualLocal f)-1)
		in ret end
	| false => InReg(tigertemp.newtemp())
val allocArg = allocLocal
fun formals(f: frame) = #accesses f
fun string(l, s) = l^tigertemp.makeString(s)^"\n"
fun exp(InFrame k) e = MEM(BINOP(PLUS, TEMP(fp), CONST k))
| exp(InReg l) e = TEMP l
fun externalCall(s, l) = CALL(NAME s, l)

fun procEntryExit1 (frame,body) = body
end
