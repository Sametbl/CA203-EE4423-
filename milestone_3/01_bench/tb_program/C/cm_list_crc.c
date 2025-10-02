#include "coremark.h"

/* golden tables + mapping (from core_main.c) */
static ee_u16 list_known_crc[]   = { 0xd4b0, 0x3340, 0x6a79, 0xe714, 0xe3c1 };
static ee_u16 matrix_known_crc[] = { 0xbe52, 0x1199, 0x5608, 0x1fd7, 0x0747 };
static ee_u16 state_known_crc[]  = { 0x5e47, 0x39bf, 0xe5a4, 0x8e3a, 0x8d84 };

static ee_s16 pick_known_id(ee_u16 c){
  switch(c){case 0x8a02:return 0;case 0x7b05:return 1;case 0x4eaf:return 2;case 0xe9f5:return 3;case 0x18f2:return 4;default:return -1;}
}

int main(void){
  core_results res;
  portable_init(&res.port, 0, 0);

  res.seed1=get_seed_32(1);
  res.seed2=get_seed_32(2);
  res.seed3=get_seed_32(3);
  res.iterations=1;
  res.execs=ID_LIST|ID_MATRIX|ID_STATE;

  /* carve stack like CoreMark: 3 equal slices */
  ee_u8 stack_memblock[TOTAL_DATA_SIZE];
  res.size = TOTAL_DATA_SIZE/3;
  res.memblock[0]=stack_memblock;
  res.memblock[1]=(void*)(stack_memblock + res.size*0);
  res.memblock[2]=(void*)(stack_memblock + res.size*1);
  res.memblock[3]=(void*)(stack_memblock + res.size*2);

  /* init all kernels (matrix/state CRCs are produced via calc_func inside list) */
  res.list = core_list_init(res.size, (list_head*)res.memblock[1], res.seed1);
  core_init_matrix(res.size, res.memblock[2], (ee_s32)res.seed1 | ((ee_s32)res.seed2<<16), &res.mat);
  core_init_state(res.size, res.seed1, res.memblock[3]);

  iterate(&res);  /* runs list forward+reverse; sets crclist+crcmatrix+crcstate */

  ee_u16 seedcrc=0;
  seedcrc=crc16(res.seed1,seedcrc);
  seedcrc=crc16(res.seed2,seedcrc);
  seedcrc=crc16(res.seed3,seedcrc);
  seedcrc=crc16(res.size, seedcrc);
  ee_s16 id=pick_known_id(seedcrc);

  ee_printf("seedcrc=0x%04x\n", seedcrc);

  /* self-check just LIST */
  if (id>=0){
    ee_printf("LIST:   got=0x%04x expect=0x%04x  %s\n",
      res.crclist, list_known_crc[id],
      (res.crclist==list_known_crc[id])?"PASS":"FAIL");
  } else {
    ee_printf("LIST:   got=0x%04x (no golden for these seeds/size)\n", res.crclist);
  }

  /* optional visibility for others */
  if (id>=0) ee_printf("MATRIX: got=0x%04x expect=0x%04x\n", res.crcmatrix, matrix_known_crc[id]);
  else       ee_printf("MATRIX: got=0x%04x (no golden)\n", res.crcmatrix);
  if (id>=0) ee_printf("STATE:  got=0x%04x expect=0x%04x\n", res.crcstate, state_known_crc[id]);
  else       ee_printf("STATE:  got=0x%04x (no golden)\n", res.crcstate);

  portable_fini(&res.port);
  return 0;
}
