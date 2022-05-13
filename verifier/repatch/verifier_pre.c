/**************************************************************************/
/*  This file is part of CertrBPF,                                        */
/*  a formally verified rBPF verifier + interpreter + JIT in Coq.         */
/*                                                                        */
/*  Copyright (C) 2022 Inria                                              */
/*                                                                        */
/*  This program is free software; you can redistribute it and/or modify  */
/*  it under the terms of the GNU General Public License as published by  */
/*  the Free Software Foundation; either version 2 of the License, or     */
/*  (at your option) any later version.                                   */
/*                                                                        */
/*  This program is distributed in the hope that it will be useful,       */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of        */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         */
/*  GNU General Public License for more details.                          */
/*                                                                        */
/**************************************************************************/

#include "verifier.h"
#include <stdint.h> /* for uintptr_t */

static __attribute__((always_inline)) inline unsigned int eval_ins_len(struct verifier_state* st)
{
  return (*st).ins_len;
}

static __attribute__((always_inline)) inline unsigned long long eval_ins(struct verifier_state* st, unsigned int idx)
{
  return *((*st).ins + idx);
}

/*******************below code are automatically generated by dx (after repatch) ***************************/
