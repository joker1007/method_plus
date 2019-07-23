#include "method_plus.h"

VALUE rb_mMethodPlus;

static VALUE
get_current_iseq(int argc, VALUE *argv, VALUE mod)
{
  return rb_thread_current();
}

void
Init_method_plus(void)
{
  rb_define_method(rb_mKernel, "get_current_iseq", get_current_iseq, 1);
}
