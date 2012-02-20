#include "EXTERN.h"
#include "perl.h"
#include "callchecker0.h"
#include "XSUB.h"

#define SVt_PADNAME SVt_PVMG

#ifndef COP_SEQ_RANGE_LOW_set
# define COP_SEQ_RANGE_LOW_set(sv,val) \
  do { ((XPVNV *)SvANY(sv))->xnv_u.xpad_cop_seq.xlow = val; } while (0)
# define COP_SEQ_RANGE_HIGH_set(sv,val) \
  do { ((XPVNV *)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh = val; } while (0)
#endif

#ifndef PERL_PADSEQ_INTRO
# define PERL_PADSEQ_INTRO I32_MAX
#endif

static PADOFFSET
pad_add_my_scalar_pvn (pTHX_ const char *namepv, STRLEN namelen)
{
  PADOFFSET offset;
  SV *namesv, *myvar;

  myvar = *av_fetch(PL_comppad, AvFILLp(PL_comppad) + 1, 1);
  offset = AvFILLp(PL_comppad);
  SvPADMY_on(myvar);

  PL_curpad = AvARRAY(PL_comppad);
  namesv = newSV_type(SVt_PADNAME);
  sv_setpvn(namesv, namepv, namelen);

  COP_SEQ_RANGE_LOW_set(namesv, PL_cop_seqmax);
  COP_SEQ_RANGE_HIGH_set(namesv, PERL_PADSEQ_INTRO);
  PL_cop_seqmax++;

  av_store(PL_comppad_name, offset, namesv);

  return offset;

}

typedef struct hook_St {
  UV level;
  CV *cb;
  struct hook_St *next;
} hook_t;

static hook_t *hooks = NULL;

static SV *make_guard;

static void
mybhk_post_end (pTHX_ OP **o)
{
  hook_t *h, *p = NULL;

  for (h = hooks; h; p = h, h = h ? h->next : NULL) {
    if (h->level > 0) {
      h->level--;

      if (h->level == 0) {
        OP *pvarop;
        SV *cb;

        pvarop = newOP(OP_PADSV, (OPpLVAL_INTRO << 8));
        pvarop->op_targ = pad_add_my_scalar_pvn(aTHX_ STR_WITH_LEN("$moo::kooh"));

        //h->op->op_targ = pvarop->op_targ;
        cb = h->cb;

        if (p)
          p->next = h->next;
        else {
          hooks = h->next;
          h = hooks;
        }
        free(h);

        //pvarop->op_ppaddr = my_padsv;

        /*
        hook = newOP(OP_RAND, 0);
        hook->op_ppaddr = invoke_cb;
        hook->op_first = h;
        *o = op_prepend_elem(OP_LINESEQ, *o, hook);
        */

        *o = op_prepend_elem(OP_LINESEQ,
                             newASSIGNOP(OPf_STACKED, pvarop, 0,
                                         newUNOP(OP_ENTERSUB, OPf_STACKED,
                                                 op_append_elem(OP_LIST,
                                                                newSVOP(OP_CONST, 0, cb),
                                                                newCVREF(0, newSVOP(OP_CONST, 0, SvREFCNT_inc(make_guard)))))),
                             *o);
      }
    }
  }
}

static void
mybhk_start (pTHX_ int full)
{
  hook_t *h;

  if (!full)
    return;

  for (h = hooks; h; h = h->next) {
    if (h->level > 0)
      h->level++;
  }
}

static BHK bhk_hooks;

/*
static OP *
configure_hook (pTHX)
{
  dSP;
  dMARK;
  dTARGET;

  sv_setsv(TARG, POPs);

  SP = MARK;
  if (GIMME_V == G_SCALAR)
    XPUSHs(&PL_sv_undef);

  RETURN;
}

static OP *
myck_entersub_foo (pTHX_ OP *entersubop, GV *namegv, SV *protosv)
{
  hook_t *hook;
  OP *hookop, *svop;
  OP *listop, *lastop, *rv2cvop;

  PERL_UNUSED_ARG(namegv);
  PERL_UNUSED_ARG(protosv);

  entersubop = ck_entersub_args_list(entersubop);
  listop = cUNOPx(entersubop)->op_first;
  if (!listop)
    croak("fail");

  entersubop->op_flags &= ~OPf_KIDS;
  cUNOPx(entersubop)->op_first = NULL;
  op_free(entersubop);

  lastop = cLISTOPx(listop)->op_first;
  while (lastop->op_sibling != cLISTOPx(listop)->op_last)
    lastop = lastop->op_sibling;
  rv2cvop = lastop->op_sibling;

  lastop->op_sibling = NULL;
  cLISTOPx(listop)->op_last = lastop;
  op_free(rv2cvop);

  NewOpSz(0, hookop, sizeof(UNOP));
  hookop->op_type = OP_RAND;
  hookop->op_ppaddr = configure_hook;
  cUNOPx(hookop)->op_flags = OPf_KIDS;
  cUNOPx(hookop)->op_first = listop;

  svop = cLISTOPx(listop)->op_first->op_sibling;
  if (svop->op_type != OP_CONST)
    croak("not const");

  hook = malloc(sizeof(hook_t));
  hook->level = SvUV(cSVOPx(svop)->op_sv);
  hook->next = hooks;
  hook->op = hookop;
  hooks = hook;

  return hookop;
}

*/

MODULE = Hook::EndOfRuntime  PACKAGE = Hook::EndOfRuntime

void
after_runtime (UV level, SV *cb)
  PREINIT:
    hook_t *hook;
  CODE:
    hook = malloc(sizeof(hook_t));
    hook->level = level;
    hook->cb = newSVsv(cb);
    hook->next = hooks;
    hooks = hook;

BOOT:
  make_guard = newRV_inc(get_cv("Hook::EndOfRuntime::_make_guard", 0));
  BhkENTRY_set(&bhk_hooks, bhk_post_end, mybhk_post_end);
  BhkENTRY_set(&bhk_hooks, bhk_start, mybhk_start);
  Perl_blockhook_register(aTHX_ &bhk_hooks);
