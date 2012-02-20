#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static void
run_hook (pTHX_ SV *hook)
{
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  call_sv(hook, G_VOID|G_DISCARD);

  FREETMPS;
  LEAVE;
}

static OP *
register_hook (pTHX)
{
  dSP;
  SV *hook;

  hook = newSVsv(POPs);

  SAVEFREESV(hook);
  SAVEDESTRUCTOR_X(run_hook, hook);

  if (GIMME_V != G_VOID)
    PUSHs(&PL_sv_undef);

  RETURN;
}

static OP *
gen_register_hook_op (pTHX_ SV *cb)
{
  OP *register_hook_op;

  register_hook_op = newUNOP(OP_RAND, 0, newSVOP(OP_CONST, 0, cb));
  register_hook_op->op_ppaddr = register_hook;

  return register_hook_op;
}

typedef struct hook_St {
  UV level;
  SV *cb;
  struct hook_St *next;
  struct hook_St *prev;
} hook_t;

static hook_t *hooks = NULL;

static void
mybhk_post_end (pTHX_ OP **o)
{
  hook_t *h;

  for (h = hooks; h;) {
    hook_t *next_h = h->next;

    if (h->level > 0)
      h->level--;

    if (h->level == 0) {
      SV *cb = cb = h->cb;

      if (h->prev) {
        h->prev->next = h->next;
        h->next->prev = h->prev;
      }
      else {
        hooks = h->next;
        if (hooks)
          hooks->prev = NULL;
      }
      free(h);

      *o = op_prepend_elem(OP_LINESEQ, gen_register_hook_op(aTHX_ cb), *o);
    }

    h = next_h;
  }
}

static void
mybhk_start (pTHX_ int full)
{
  hook_t *h;

  if (!full)
    return;

  for (h = hooks; h; h = h->next)
    h->level++;
}

static BHK bhk_hooks;

MODULE = Hook::EndOfRuntime  PACKAGE = Hook::EndOfRuntime

void
after_runtime (UV level, SV *cb)
  PREINIT:
    hook_t *hook;
  CODE:
    hook = malloc(sizeof(hook_t));
    hook->level = level;
    hook->cb = newSVsv(cb);
    hook->prev = NULL;
    hook->next = hooks;
    if (hooks)
      hooks->prev = hook;
    hooks = hook;

BOOT:
  BhkENTRY_set(&bhk_hooks, bhk_post_end, mybhk_post_end);
  BhkENTRY_set(&bhk_hooks, bhk_start, mybhk_start);
  Perl_blockhook_register(aTHX_ &bhk_hooks);
