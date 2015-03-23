open HolKernel ast_vsm0Theory integerTheory lcsymtacs pairTheory arithmeticTheory relationTheory bossLib intSimps smallstep_vsm0Theory listTheory pairTheory;

val _ = new_theory "basic_block"

(* Composition Theorems *)
val concat_right_thm = prove(``!P c c'.vsm_exec P c c' ==> !P'.vsm_exec (P ++ P') c c'``, cheat);
val incr_pc_def = Define `(incr_pc (a, b) (c:int) = (a + c, b))`;
val concat_left_thm = prove(``!P c c'.vsm_exec P c c' ==> !P'.vsm_exec (P' ++ P) (incr_pc c (&LENGTH P')) (incr_pc c' (&LENGTH P'))``, cheat);

val vsm_exec_det = prove(``!P c c'.vsm_exec P c c' ==> !c''.vsm_exec P c c'' ==> vsm_exec P c' c'' \/ vsm_exec P c'' c'``,cheat)

val fsa = FULL_SIMP_TAC (srw_ss () ++ intSimps.INT_ARITH_ss);

val cannot_jump_to_n_def = Define `(cannot_jump_to_n n pc (VSM_Jump x) = (&pc + x + 1 <> n)) /\
(cannot_jump_to_n n pc (VSM_Jz x) = ((&pc + x + 1) <> n)) /\
(cannot_jump_to_n n pc _ = T)`;

val no_jumps_to_instr_def = Define `no_jumps_to_instr prog n = EVERYi (cannot_jump_to_n (&n)) prog`;


val every_thm = prove(``!f l.EVERYi f l <=> (!n. (n < LENGTH l) ==> f n (EL n l))``,
fs [EQ_IMP_THM] THEN
Induct_on `l` THEN rw [EVERYi_DEF] THEN1 (Cases_on `n` THEN fs [EVERYi_DEF, EL] THEN res_tac THEN fs [] THEN fs [])

THEN1 (`0 < SUC (LENGTH l)` by decide_tac THEN res_tac THEN fs [EL])

THEN`!n. n < LENGTH l ==> f (SUC n) (EL (SUC n) (h::l))` by fs []
THEN `!n. n < LENGTH l ==> (f o SUC) n (EL (SUC n) (h::l))` by fs []
THEN fs [EL]);

val no_jump_imp_pred = prove(``!P n.no_jumps_to_instr P n ==> !stk stk' pc.vsm_exec_one P (pc, stk) (&n, stk') ==> (&n = pc + 1)``,
rw []
THEN fs [vsm_exec_one_cases]
THEN Cases_on `P !! pc` THEN fs [vsm_exec_instr_cases]
THEN fs [no_jumps_to_instr_def]
THEN imp_res_tac every_thm
THEN `?npc.pc = &npc` by metis_tac [NUM_POSINT_EXISTS, int_ge] THEN rw []
THEN `npc < LENGTH P` by fs []
THEN res_tac
THEN `EL npc P = VSM_Jump i` by cheat (*proof somewhere else*)
THEN rw []
THEN fs [cannot_jump_to_n_def] THEN fsa []);



val subseq_def = Define `subseq start n = (TAKE n) o (DROP start)`;

val replace_subseq_def = Define `replace_subseq start l rep = (TAKE start l) ++ rep ++ (DROP (start + LENGTH rep) l)`;

val prog_equiv_def = Define `prog_equiv a b = !stk.(LENGTH a = LENGTH b) /\ !pc' stk'.((pc' < 0) \/ (&LENGTH a <= pc')) ==> (vsm_exec a (0, stk) (pc', stk') <=> vsm_exec b (0, stk) (pc', stk'))`;


val cheat1 = prove(``!A B.safe_range (A ++ B) (LENGTH A) (LENGTH (A ++ B)) ==> !c c''.(vsm_exec_one (A ++ B))^* c c'' ==> (FST c < &LENGTH A) /\ (&LENGTH A <= FST c'') /\ (FST c'' < &LENGTH (A ++ B)) ==> ?stk'.(vsm_exec_one (A ++ B))^* c (&LENGTH A, stk') /\ (vsm_exec_one (A ++ B))^* (&LENGTH A, stk') c''``, cheat)


STRIP_TAC THEN STRIP_TAC THEN DISCH_TAC THEN ho_match_mp_tac RTC_STRONG_INDUCT THEN rw [] THEN1 fsa [] THEN Cases_on `c` THEN Cases_on `c''` THEN Cases_on `c'` THEN fs [FST] THEN fs [safe_range_def] THEN Cases_on `q'' < &LENGTH A` THEN1 (fs [] THEN Q.EXISTS_TAC `stk'` THEN rw [Once RTC_CASES1] THEN DISJ2_TAC THEN Q.EXISTS_TAC `(q'', r'')` THEN rw [])

`q'' < &LENGTH A + &LENGTH B` by cheat



 THEN `0 <= q'` by fsa [] THEN `?nq'.q' = &nq'` by fsa [NUM_POSINT_EXISTS] THEN rw [] THEN `LENGTH A <= nq'` by fsa [] THEN `nq' < LENGTH A + LENGTH B` by fsa [] THEN res_tac THEN imp_res_tac no_jump_imp_pred


val safe_range_def = Define `safe_range P a b = !n.(a <= n) /\ (n < b) ==> no_jumps_to_instr P n /\ ~in_is_jmp (EL n P)`;

safe_range P 0 (LENGTH P) ==> !c c'.vsm_exec P c c' ==> !n. (FST c <= n) /\ (n <= FST c') ==> ?stk'.vsm_exec P c (n, stk')
STRIP_TAC
fs [vsm_exec_def]
HO_MATCH_MP_TAC RTC_STRONG_INDUCT THEN rw []

THEN1 (`n = FST c` by fsa [] THEN rw [] THEN  Cases_on `c` THEN fs [FST] THEN metis_tac [RTC_REFL])

`0 <= FST c` by cheat

Cases_on `c` THEN Cases_on `c'` THEN Cases_on `c''` THEN fs [FST]

fs [vsm_exec_one_cases, safe_range_def]
`?nq.q = &nq` by fsa [NUM_POSINT_EXISTS] THEN rw []

`~in_is_jmp (EL nq P)` by fsa []

`P !! &nq = EL nq P` by cheat THEN rw []

Cases_on `EL nq P` THEN fs [vsm_exec_instr_cases, in_is_jmp_def] THEN rw []

Cases_on `&nq = n` THEN rw [] THEN1 metis_tac [RTC_REFL]

`&nq + 1 <= n` by fsa []

res_tac

rw [Once RTC_CASES1]

THEN Q.LIST_EXISTS_TAC [`stk'`, `(&nq + 1, r)`] THEN rw [] THEN fs [vsm_exec_one_cases, vsm_exec_instr_cases]

Cases_on `c` THEN fs [FST]
fs [safe_range_def]
`0 <= n` by cheat
`(q = n) \/ (q < &LENGTH P)` by cheat
rw [] THEN Q.EXISTS_TAC `r` THEN metis_tac [RTC_REFL]

`?nq.q = &nq` by fsa [NUM_POSINT_EXISTS] THEN rw []

`nq < LENGTH P` by fsa []

res_tac
rw [Once RTC_CASES1]
Cases_on `&nq = n` THEN1 (Q.EXISTS_TAC `r` THEN rw []) THEN fs [vsm_exec_one_cases]
`P !! &nq = EL nq P` by cheat THEN rw []

Cases_on `EL nq P` THEN fs [vsm_exec_instr_cases] THEN metis_tac []

!A B B'.prog_equiv B B' /\ safe_range (A ++ B) (LENGTH A) (LENGTH (A ++ B)) ==> !c c'.(vsm_exec_one (A ++ B))^* c c' ==> (FST c' < 0) \/ (&LENGTH (A++B) <= FST c') ==> (vsm_exec_one (A ++ B'))^* c c'

rw []
Cases_on `c` THEN Cases_on `c'` THEN fs [FST]




STRIP_TAC
ho_match_mp_tac RTC_STRONG_INDUCT THEN rw [] THEN Cases_on `c` THEN Cases_on `c'` THEN Cases_on `c''` THEN fs [FST]

Cases_on `q < &LENGTH A`

rw [Once RTC_CASES1]
DISJ2_TAC

`0 <= q` by cheat



THEN rw [Once RTC_CASES1] THEN DISJ2_TAC THEN  
!A B C.vsm_exec_one (A ++ B)



!A B C B'.safe_range (A ++ B ++ C) (LENGTH A) (LENGTH B)  /\ prog_equiv B B' ==> prog_equiv (A ++ B ++ C) (A ++ B' ++ C)

rw []


fs [prog_equiv_def] THEN rw []

rw [EQ_IMP_THM]

fs [vsm_exec_def]

fs [Once RTC_CASES_RTC_TWICE]

Cases_on `u`

Cases_on `q < 0`

THEN1 (`q = pc'` by imp_res_tac RTC_CASES1 THEN fsa [vsm_exec_one_cases] THEN rw [])


!a b P repl.safe_range 



!a b P repl.safe_range P a b /\ prog_equiv (subseq a (b-a) P) repl ==> prog_equiv P (replace_subseq a repl P)

rw []

fs [prog_equiv_def, replace_subseq]

val in_is_jmp_def = Define `(in_is_jmp (VSM_Jump x) = T) /\ (in_is_jmp (VSM_Jz x) = T) /\ (in_is_jmp _ = F)`;

val get_bb_len_def = bossLib.tDefine "get_bb_len" `get_bb_len prog start_ind = if (start_ind >= LENGTH prog) then 0 else

if ~no_jumps_to_instr prog (SUC start_ind)
                                                         then (1:num)
                                                         else 1 + get_bb_len prog (SUC start_ind)` (WF_REL_TAC `measure (\ (x, a).LENGTH x - a)`);

val bbs_def = bossLib.tDefine "bbs" `(bbs prog pc [] = []) /\ (bbs prog pc (i::ins : vsm_prog) = if (pc >= LENGTH prog) then [] else let length = get_bb_len prog pc
in (if length <= 0 then [i]::(bbs prog (pc + 1) ins)
   else (TAKE length (i::ins))::(bbs prog (pc + length) (DROP length (i::ins)))))` (WF_REL_TAC `measure (\(prog, pc, prog').LENGTH prog - pc)`); 


val test_prog = ``[VSM_Push 0; VSM_Pop; VSM_Push 20; VSM_Store 2; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Push 5; VSM_Jump (-3)]``;


fun snd (a, b) = b;

fun term conv term = snd (dest_eq (snd (dest_thm (conv term))))

fun try conv t = term conv t handle UNCHANGED => t

val foo = EVAL ``bbs ^test_prog 0 ^test_prog``

intSimps.ADDL_CANON_CONV (term EVAL ``bbs ^test_prog 0 ^test_prog``)

val append_all_def = Define `(append_all [] = []) /\ (append_all (x::xs) = x ++ (append_all xs))`;

val append_all_def = Define `append_all ps = FOLDL $++ ps`;

(* Assembly for while !x >= 3 + !y do (z := !z + 1);while !y >= 3 + !z do a := !a + -1 *)
val test_prog = ``[VSM_Push 0; VSM_Pop; VSM_Load 2; VSM_Store 1; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Push 3; VSM_Load 1; VSM_Geq; VSM_Store 0; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Load 5; VSM_Load 0; VSM_Plus; VSM_Jz 92; VSM_Tick; VSM_Push 0; VSM_Pop; VSM_Load 8; VSM_Store 9; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Push 1; VSM_Load 9; VSM_Plus; VSM_Store 8; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Load 5; VSM_Store 4; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Push 3; VSM_Load 4; VSM_Geq; VSM_Store 3; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Load 8; VSM_Load 3; VSM_Plus; VSM_Jz 34; VSM_Tick; VSM_Push 0; VSM_Pop; VSM_Load 6; VSM_Store 7; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Push (-1); VSM_Load 7; VSM_Plus; VSM_Store 6; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Load 5; VSM_Store 4; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Push 3; VSM_Load 4; VSM_Geq; VSM_Store 3; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Jump (-38); VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Load 2; VSM_Store 1; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Push 3; VSM_Load 1; VSM_Geq; VSM_Store 0; VSM_Push 0; VSM_Pop; VSM_Push 0; VSM_Pop; VSM_Jump (-96); VSM_Push 0; VSM_Pop; VSM_Push 0]``;

val bbs = term EVAL ``bbs ^test_prog 0 ^test_prog``;

open listSimps

EVAL ``append_all ^bbs``

!P A P'.(P = P') /\ (A = 0) ==> (append_all (bbs P A P') = P)
recInduct (fetch "-" "bbs_ind")

THEN rw [] THEN1 EVAL_TAC

Cases_on `i` THEN fs [bbs_def] THEN rw [] THEN1 (fs [GREATER_EQ]) THEN Cases_on `length` fs THEN rw [] 

[NOT_GREATER_EQ]


EVAL_TAC



 val _ = export_theory (); 
