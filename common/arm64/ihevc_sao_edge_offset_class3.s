///*****************************************************************************
//*
//* Copyright (C) 2012 Ittiam Systems Pvt Ltd, Bangalore
//*
//* Licensed under the Apache License, Version 2.0 (the "License");
//* you may not use this file except in compliance with the License.
//* You may obtain a copy of the License at:
//*
//* http://www.apache.org/licenses/LICENSE-2.0
//*
//* Unless required by applicable law or agreed to in writing, software
//* distributed under the License is distributed on an "AS IS" BASIS,
//* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//* See the License for the specific language governing permissions and
//* limitations under the License.
//*
//*****************************************************************************/
///**
//*******************************************************************************
//* ,:file
//*  ihevc_sao_edge_offset_class3.s
//*
//* ,:brief
//*  Contains function definitions for inter prediction  interpolation.
//* Functions are coded using NEON  intrinsics and can be compiled using@ ARM
//* RVCT
//*
//* ,:author
//*  Parthiban V
//*
//* ,:par List of Functions:
//*
//*
//* ,:remarks
//*  None
//*
//*******************************************************************************
//*/
//void ihevc_sao_edge_offset_class3(UWORD8 *pu1_src,
//                              WORD32 src_strd,
//                              UWORD8 *pu1_src_left,
//                              UWORD8 *pu1_src_top,
//                              UWORD8 *pu1_src_top_left,
//                              UWORD8 *pu1_src_top_right,
//                              UWORD8 *pu1_src_bot_left,
//                              UWORD8 *pu1_avail,
//                              WORD8 *pi1_sao_offset,
//                              WORD32 wd,
//                              WORD32 ht)
//**************Variables Vs Registers*****************************************
//x0 =>    *pu1_src
//x1 =>    src_strd
//x2 =>    *pu1_src_left
//x3 =>    *pu1_src_top
//x4    =>    *pu1_src_top_left
//x5    =>    *pu1_avail
//x6    =>    *pi1_sao_offset
//x7    =>    wd
//x8=>    ht

.text
.p2align 2

.include "ihevc_neon_macros.s"

.globl gi1_table_edge_idx
.globl ihevc_sao_edge_offset_class3_av8

ihevc_sao_edge_offset_class3_av8:


    // STMFD sp!,{x4-x12,x14}            //stack stores the values of the arguments
    stp         x19, x20,[sp,#-16]!
    stp         x21, x22,[sp,#-16]!
    stp         x23, x24,[sp,#-16]!

    MOV         x19,x0                      //Store pu1_src in sp
    MOV         x21,x6                      //Store pu1_src_left in sp
    MOV         x22,x3                      //Store pu1_src_top in sp
    MOV         x23,x7                      //Store pu1_avail in sp
    MOV         x24,x4                      //Store pu1_src_top_left in sp
    MOV         x20,x5                      //Store pu1_src_top_right in sp
    MOV         x13,x6                      //Store pu1_src_bot_left in sp

    MOV         x5,x7                       //Loads pu1_avail

    LDR         x6,[sp,#48]                 //Loads pi1_sao_offset
    LDR         w7,[sp,#56]                 //Loads wd
    LDR         w8,[sp,#64]                 //Loads ht

    MOV         x16,x7 // wd
    MOV         x17,x8 // ht

    SUB         x9,x7,#1                    //wd - 1

    LDRB        w10,[x3,x9]                 //pu1_src_top[wd - 1]

    MOV         x9,x7                       //Move width to x9 for loop count

    SUB         sp,sp,#0xA0                 //Decrement the stack pointer to store some temp arr values

    STRB        w10,[sp]                    //u1_src_top_left_tmp = pu1_src_top[wd - 1]
    SUB         x10,x8,#1                   //ht-1
    madd        x11, x10, x1, x0            //pu1_src[(ht - 1) * src_strd + col]
    ADD         x12,sp,#0x02                //temp array

AU1_SRC_TOP_LOOP:
    LD1         {v0.8b},[x11],#8            //pu1_src[(ht - 1) * src_strd + col]
    SUBS        x9,x9,#8                    //Decrement the loop count by 8
    ST1         {v0.8b},[x12],#8            //au1_src_top_tmp[col] = pu1_src[(ht - 1) * src_strd + col]
    BNE         AU1_SRC_TOP_LOOP

PU1_AVAIL_5_LOOP:
    LDRB        w9,[x5,#5]                  //pu1_avail[5]
    CMP         x9,#0
    SUB         x10,x7,#1                   //[wd - 1]
    LDRB        w9,[x0,x10]                 //u1_pos_0_0_tmp = pu1_src[wd - 1]
    BEQ         PU1_AVAIL_6_LOOP

    MOV         x11,x20                     //Load pu1_src_top_right from sp
    SUB         x10,x10,#1                  //[wd - 1 - 1]

    LDRB        w11,[x11]                   //pu1_src_top_right[0]
    SUB         x12,x9,x11                  //pu1_src[wd - 1] - pu1_src_top_right[0]

    ADD         x11,x0,x1                   //pu1_src + src_strd

    LDRB        w14,[x11,x10]               //pu1_src[wd - 1 - 1 + src_strd]
    CMP         x12,#0
    movn        x20,#0
    csel        x12, x20, x12,LT
    SUB         x11,x9,x14                  //pu1_src[wd - 1] - pu1_src[wd - 1 - 1 + src_strd]

    MOV         x20,#1
    csel        x12, x20, x12,GT            //SIGN(pu1_src[wd - 1] - pu1_src_top_right[0])
    CMP         x11,#0
    movn        x20,#0
    csel        x11, x20, x11,LT
    MOV         x20,#1
    csel        x11, x20, x11,GT            //SIGN(pu1_src[wd - 1] - pu1_src[wd - 1 - 1 + src_strd])
    ADRP        x14, :got:gi1_table_edge_idx //table pointer
    LDR         x14, [x14, #:got_lo12:gi1_table_edge_idx]
    ADD         x11,x12,x11                 //SIGN(pu1_src[wd - 1] - pu1_src_top_right[0]) +  SIGN(pu1_src[wd - 1] - pu1_src[wd - 1 - 1 + src_strd])
    ADD         x11,x11,#2                  //edge_idx

    LDRSB       x12,[x14,x11]               //edge_idx = gi1_table_edge_idx[edge_idx]
    CMP         x12,#0                      //0 != edge_idx
    BEQ         PU1_AVAIL_6_LOOP
    LDRSB       x10,[x6,x12]                //pi1_sao_offset[edge_idx]
    ADD         x9,x9,x10                   //pu1_src[0] + pi1_sao_offset[edge_idx]
    mov         x20,#255
    cmp         x9,x20
    csel        x9, x20, x9, ge             //u1_pos_0_0_tmp = CLIP3(pu1_src[0] + pi1_sao_offset[edge_idx], 0, (1 << bit_depth) - 1)
    mov         x20,#0
    cmp         x9,x20
    csel        x9, x20, x9, LT             //u1_pos_0_0_tmp = CLIP3(pu1_src[0] + pi1_sao_offset[edge_idx], 0, (1 << bit_depth) - 1)

PU1_AVAIL_6_LOOP:
    LDRB        w10,[x5,#6]                 //pu1_avail[6]
    SUB         x11,x8,#1                   //ht - 1

    CMP         x10,#0
    madd        x12, x11, x1, x0            //pu1_src[(ht - 1) * src_strd]

    LDRB        w10,[x12]                   //u1_pos_wd_ht_tmp = pu1_src[(ht - 1) * src_strd]
    BEQ         PU1_AVAIL_3_LOOP

    MOV         x14,x13                     //Load pu1_src_bot_left from sp
    SUB         x11,x12,x1                  //pu1_src[(ht - 1) * src_strd) - src_strd]

    LDRB        w14,[x14]                   //Load pu1_src_bot_left[0]
    ADD         x11,x11,#1                  //pu1_src[(ht - 1) * src_strd + 1 - src_strd]

    LDRB        w11,[x11]                   //Load pu1_src[(ht - 1) * src_strd + 1 - src_strd]
    SUB         x14,x10,x14                 //pu1_src[(ht - 1) * src_strd] - pu1_src_bot_left[0]

    SUB         x11,x10,x11                 //pu1_src[(ht - 1) * src_strd] - pu1_src[(ht - 1) * src_strd + 1 - src_strd]
    CMP         x11,#0
    movn        x20,#0
    csel        x11, x20, x11,LT
    MOV         x20,#1
    csel        x11, x20, x11,GT            //SIGN(pu1_src[(ht - 1) * src_strd] - pu1_src[(ht - 1) * src_strd + 1 - src_strd])

    CMP         x14,#0
    movn        x20,#0
    csel        x14, x20, x14,LT
    MOV         x20,#1
    csel        x14, x20, x14,GT            //SIGN(pu1_src[(ht - 1) * src_strd] - pu1_src_bot_left[0])

    ADD         x11,x11,x14                 //Add 2 sign value

    ADRP        x14, :got:gi1_table_edge_idx //table pointer
    LDR         x14, [x14, #:got_lo12:gi1_table_edge_idx]
    ADD         x11,x11,#2                  //edge_idx

    LDRSB       x12,[x14,x11]               //edge_idx = gi1_table_edge_idx[edge_idx]
    CMP         x12,#0
    BEQ         PU1_AVAIL_3_LOOP
    LDRSB       x11,[x6,x12]                //pi1_sao_offset[edge_idx]
    ADD         x10,x10,x11                 //pu1_src[(ht - 1) * src_strd] + pi1_sao_offset[edge_idx]
    mov         x20,#255
    cmp         x10,x20
    csel        x10, x20, x10, ge           //u1_pos_wd_ht_tmp = CLIP3(pu1_src[(ht - 1) * src_strd] + pi1_sao_offset[edge_idx], 0, (1 << bit_depth) - 1)
    mov         x20,#0
    cmp         x10,x20
    csel        x10, x20, x10, LT           //u1_pos_wd_ht_tmp = CLIP3(pu1_src[(ht - 1) * src_strd] + pi1_sao_offset[edge_idx], 0, (1 << bit_depth) - 1)

PU1_AVAIL_3_LOOP:
    MOV         x21,x2
    MOV         x12,x8                      //Move ht

    MOV         x14,x2                      //Move pu1_src_left to pu1_src_left_cpy
    movi        v0.16b, #2                  //const_2 = vdupq_n_s8(2)
    LDRB        w11,[x5,#3]                 //pu1_avail[3]

    CMP         x11,#0
    movi        v2.8h, #0                   //const_min_clip = vdupq_n_s16(0)
    SUB         x20,x12,#1                  //ht_tmp--
    csel        x12, x20, x12,EQ

    LDRB        w5,[x5,#2]                  //pu1_avail[2]
    movi        v4.8h, #255                 //const_max_clip = vdupq_n_u16((1 << bit_depth) - 1)
    CMP         x5,#0

    ADD         x20,x0,x1                   //pu1_src += src_strd
    csel        x0, x20, x0,EQ
    LD1         {v7.8b},[x6]                //offset_tbl = vld1_s8(pi1_sao_offset)
    SUB         x20,x12,#1                  //ht_tmp--
    csel        x12, x20, x12,EQ

    ADRP        x6, :got:gi1_table_edge_idx //table pointer
    LDR         x6, [x6, #:got_lo12:gi1_table_edge_idx]

    movi        v1.16b, #0xFF               //au1_mask = vdupq_n_s8(-1)
    ADD         x20,x14,#1                  //pu1_src_left_cpy += 1
    csel        x14, x20, x14,EQ

    MOV         x15,x0                      //Store pu1_src in sp
    LD1         {v6.8b},[x6]                //edge_idx_tbl = vld1_s8(gi1_table_edge_idx)
    MOV         x6,x7                       //move wd to x6 loop_count

    CMP         x7,#16                      //Compare wd with 16
    BLT         WIDTH_RESIDUE               //If not jump to WIDTH_RESIDUE where loop is unrolled for 8 case
    CMP         x8,#4                       //Compare ht with 4
    BLE         WD_16_HT_4_LOOP             //If jump to WD_16_HT_4_LOOP

WIDTH_LOOP_16:
    MOV         x7,x16                      //Loads wd

    MOV         x5,x23                      //Loads pu1_avail
    CMP         x6,x7                       //col == wd
    LDRb        w20, [x5]                   //pu1_avail[0]
    csel        w8,w20,w8,EQ
    MOV         x20,#-1
    csel        x8, x20, x8,NE
    mov         v1.b[0], w8                 //au1_mask = vsetq_lane_s8(-1, au1_mask, 0)

    CMP         x6,#16                      //if(col == 16)
    BNE         SKIP_AU1_MASK_VAL
    LDRB        w8,[x5,#1]                  //pu1_avail[1]
    mov         v1.b[15], w8                //au1_mask = vsetq_lane_s8(pu1_avail[1], au1_mask, 15)

SKIP_AU1_MASK_VAL:
    LDRB        w8,[x5,#2]                  //pu1_avail[2]
    CMP         x8,#0

    MOV         x4,x17                      //Loads ht
    SUB         x20,x0,x1                   //pu1_src - src_strd
    csel        x8, x20, x8,EQ

    csel        x8, x3, x8,NE
    ADD         x5,sp,#0x42                 //*au1_src_left_tmp

    MOV         x7,x16                      //Loads wd
    ADD         x8,x8,#1                    //pu1_src - src_strd + 1

    SUB         x7,x7,x6                    //(wd - col)
    LD1         {v3.16b},[x8]               //pu1_top_row = vld1q_u8(pu1_src - src_strd + 1)
    ADD         x3,x3,#16

    MOV         x8,x19                      //Loads *pu1_src
    LD1         {v5.16b},[x0]               //pu1_cur_row = vld1q_u8(pu1_src)
    ADD         x7,x7,#15                   //15 + (wd - col)

    ADD         x7,x8,x7                    //pu1_src[0 * src_strd + 15 + (wd - col)]
    cmhi        v17.16b,  v5.16b ,  v3.16b  //vcgtq_u8(pu1_cur_row, pu1_top_row)
    SUB         x5,x5,#1

AU1_SRC_LEFT_LOOP:
    LDRB        w8,[x7]                     //load the value and increment by src_strd
    ADD         x7,x7,x1
    SUBS        x4,x4,#1                    //decrement the loop count
    STRB        w8,[x5,#1]!                 //store it in the stack pointer
    BNE         AU1_SRC_LEFT_LOOP

    movi        v18.16b, #0
    cmhi        v16.16b,  v3.16b ,  v5.16b  //vcltq_u8(pu1_cur_row, pu1_top_row)

    ADD         x8,x0,x1                    //I *pu1_src + src_strd
    SUB         v17.16b,  v16.16b ,  v17.16b //sign_up = vreinterpretq_s8_u8(vsubq_u8(cmp_lt, cmp_gt))
    MOV         x7,x12                      //row count, move ht_tmp to x7

    SUB         x5,x12,x7                   //I ht_tmp - row
    LD1         {v16.16b},[x8]              //I pu1_next_row = vld1q_u8(pu1_src_cpy + src_strd)
    ADD         x8,x14,x5                   //I pu1_src_left_cpy[ht_tmp - row]

    ADD         x8,x8,#1                    //I pu1_src_left_cpy[ht_tmp - row + 1]
    LDRB        w8,[x8]

    MOV         x5,x23                      //I Loads pu1_avail
    mov         v18.b[15], w8               //I vsetq_lane_u8
    LDRB        w5,[x5,#2]                  //I pu1_avail[2]

    EXT         v18.16b,  v18.16b ,  v16.16b,#15 //I pu1_next_row_tmp = vextq_u8(pu1_next_row_tmp, pu1_next_row, 15)
    CMP         x5,#0                       //I
    BNE         SIGN_UP_CHANGE_DONE         //I

SIGN_UP_CHANGE:
    LDRB        w8,[x0,#15]                 //I pu1_src_cpy[15]
    SUB         x5,x0,x1                    //I pu1_src_cpy[16 - src_strd]

    LDRB        w5,[x5,#16]                 //I load the value
    SUB         x8,x8,x5                    //I pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]
    CMP         x8,#0                       //I
    movn        x20,#0
    csel        x8, x20, x8,LT              //I
    MOV         x20,#1
    csel        x8, x20, x8,GT              //I SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd])
    mov         v17.b[15], w8               //I sign_up = vsetq_lane_s8(SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]), sign_up, 15)

SIGN_UP_CHANGE_DONE:
    cmhi        v3.16b,  v5.16b ,  v18.16b  //I vcgtq_u8(pu1_cur_row, pu1_next_row_tmp)
    cmhi        v18.16b,  v18.16b ,  v5.16b //I vcltq_u8(pu1_cur_row, pu1_next_row_tmp)
    SUB         v3.16b,  v18.16b ,  v3.16b  //I sign_down = vreinterpretq_s8_u8(vsubq_u8(cmp_lt, cmp_gt))

    ADD         v18.16b,  v0.16b ,  v17.16b //I edge_idx = vaddq_s8(const_2, sign_up)
    ADD         v18.16b,  v18.16b ,  v3.16b //I edge_idx = vaddq_s8(edge_idx, sign_down)
    TBL         v18.16b, {v6.16b},v18.16b   //I vtbl1_s8(edge_idx_tbl, vget_low_s8(edge_idx))
    NEG         v17.16b, v3.16b             //I sign_up = vnegq_s8(sign_down)

    EXT         v17.16b,  v17.16b ,  v17.16b,#1 //I sign_up = vextq_s8(sign_up, sign_up, 1)
//  TBL v19.8b, {v6.16b},v19.8b                //I vtbl1_s8(edge_idx_tbl, vget_high_s8(edge_idx))

    Uxtl        v20.8h, v5.8b               //I pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vmovl_u8(vget_low_u8(pu1_cur_row)))
    AND         v18.16b,  v18.16b ,  v1.16b //I edge_idx = vandq_s8(edge_idx, au1_mask)

    TBL         v3.16b, {v7.16b},v18.16b    //I offset = vtbl1_s8(offset_tbl, vget_low_s8(edge_idx))

    Uxtl2       v22.8h, v5.16b              //I pi2_tmp_cur_row.val[1] = vreinterpretq_s16_u16(vmovl_u8(vget_high_u8(pu1_cur_row)))
    SADDW       v20.8h,  v20.8h ,  v3.8b    //I pi2_tmp_cur_row.val[0] = vaddw_s8(pi2_tmp_cur_row.val[0], offset)

    SMAX        v20.8h,  v20.8h ,  v2.8h    //I pi2_tmp_cur_row.val[0] = vmaxq_s16(pi2_tmp_cur_row.val[0], const_min_clip)
//  TBL v11.8b, {v7.16b},v19.8b                    //I offset = vtbl1_s8(offset_tbl, vget_high_s8(edge_idx))
    UMIN        v20.8h,  v20.8h ,  v4.8h    //I pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vminq_u16(vreinterpretq_u16_s16(pi2_tmp_cur_row.val[0]), const_max_clip))

    mov         v5.16b, v16.16b
    SADDW2      v22.8h,  v22.8h ,  v3.16b   //I pi2_tmp_cur_row.val[1] = vaddw_s8(pi2_tmp_cur_row.val[1], offset)

    SMAX        v22.8h,  v22.8h ,  v2.8h    //I pi2_tmp_cur_row.val[1] = vmaxq_s16(pi2_tmp_cur_row.val[1], const_min_clip)
    UMIN        v22.8h,  v22.8h ,  v4.8h    //I pi2_tmp_cur_row.val[1] = vreinterpretq_s16_u16(vminq_u16(vreinterpretq_u16_s16(pi2_tmp_cur_row.val[1]), const_max_clip))

    SUB         x7,x7,#1                    //I Decrement the ht_tmp loop count by 1

PU1_SRC_LOOP:
    ADD         x8,x0,x1,LSL #1             //II *pu1_src + src_strd
    xtn         v20.8b,  v20.8h             //I vmovn_s16(pi2_tmp_cur_row.val[0])
    SUB         x5,x12,x7                   //II ht_tmp - row

    ADD         x4,x0,x1                    //II pu1_src_cpy[16 - src_strd]
    xtn2        v20.16b,  v22.8h            //I vmovn_s16(pi2_tmp_cur_row.val[1])
    ADD         x2,x8,x1                    //III *pu1_src + src_strd

    LDRB        w11,[x4,#15]                //II pu1_src_cpy[15]
    LD1         {v16.16b},[x8]              //II pu1_next_row = vld1q_u8(pu1_src_cpy + src_strd)
    SUB         x7,x7,#1                    //II Decrement the ht_tmp loop count by 1

    ADD         x8,x14,x5                   //II pu1_src_left_cpy[ht_tmp - row]
    LD1         {v30.16b},[x2]              //III pu1_next_row = vld1q_u8(pu1_src_cpy + src_strd)
    LDRB        w8,[x8,#1]

    LDRB        w4,[x0,#16]                 //II load the value
    mov         v18.b[15], w8               //II vsetq_lane_u8
    SUB         x11,x11,x4                  //II pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]

    CMP         x11,#0                      //II
    ST1         { v20.16b},[x0],x1          //I vst1q_u8(pu1_src_cpy, pu1_cur_row)
    SUB         x5,x12,x7                   //III ht_tmp - row

    movn        x20,#0
    csel        x11, x20, x11,LT            //II
    EXT         v18.16b,  v18.16b ,  v16.16b,#15 //II pu1_next_row_tmp = vextq_u8(pu1_next_row_tmp, pu1_next_row, 15)
    MOV         x20,#1
    csel        x11, x20, x11,GT            //II SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd])

    ADD         x8,x14,x5                   //III pu1_src_left_cpy[ht_tmp - row]
    mov         v17.b[15], w11              //II sign_up = vsetq_lane_s8(SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]), sign_up, 15)
    CMP         x7,#1                       //III

    BNE         NEXT_ROW_ELSE_2             //III
    MOV         x5,x23                      //III Loads pu1_avail
    LDRB        w5,[x5,#3]                  //III pu1_avail[3]
    CMP         x5,#0                       //III
    SUB         x20,x2,#2                   //III pu1_src_cpy[src_strd - 1]
    csel        x8, x20, x8,NE

NEXT_ROW_ELSE_2:
    LDRB        w8,[x8,#1]                  //III
    cmhi        v24.16b,  v5.16b ,  v18.16b //II vcgtq_u8(pu1_cur_row, pu1_next_row_tmp)
    ADD         x5,x0,x1

    LDRB        w2,[x5,#15]                 //III pu1_src_cpy[15]
    cmhi        v26.16b,  v18.16b ,  v5.16b //II vcltq_u8(pu1_cur_row, pu1_next_row_tmp)
    LDRB        w5,[x0,#16]                 //III load the value

    SUB         x2,x2,x5                    //III pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]
    SUB         v24.16b,  v26.16b ,  v24.16b //II sign_down = vreinterpretq_s8_u8(vsubq_u8(cmp_lt, cmp_gt))
    CMP         x2,#0                       //III

    movn        x20,#0
    csel        x2, x20, x2,LT              //III
    mov         v18.b[15], w8               //III vsetq_lane_u8
    MOV         x20,#1
    csel        x2, x20, x2,GT              //III SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd])

    SUB         x7,x7,#1                    //III Decrement the ht_tmp loop count by 1
    ADD         v26.16b,  v0.16b ,  v17.16b //II edge_idx = vaddq_s8(const_2, sign_up)

    NEG         v17.16b, v24.16b            //II sign_up = vnegq_s8(sign_down)
    EXT         v18.16b,  v18.16b ,  v30.16b,#15 //III pu1_next_row_tmp = vextq_u8(pu1_next_row_tmp, pu1_next_row, 15)

    ADD         v26.16b,  v26.16b ,  v24.16b //II edge_idx = vaddq_s8(edge_idx, sign_down)

    EXT         v17.16b,  v17.16b ,  v17.16b,#1 //II sign_up = vextq_s8(sign_up, sign_up, 1)
    TBL         v26.16b, {v6.16b},v26.16b   //II vtbl1_s8(edge_idx_tbl, vget_low_s8(edge_idx))
    cmhi        v3.16b,  v16.16b ,  v18.16b //III vcgtq_u8(pu1_cur_row, pu1_next_row_tmp)

    mov         v17.b[15], w2               //III sign_up = vsetq_lane_s8(SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]), sign_up, 15)
//  TBL v27.8b, {v6.16b},v27.8b                //II vtbl1_s8(edge_idx_tbl, vget_high_s8(edge_idx))
    cmhi        v18.16b,  v18.16b ,  v16.16b //III vcltq_u8(pu1_cur_row, pu1_next_row_tmp)

    Uxtl        v28.8h, v5.8b               //II pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vmovl_u8(vget_low_u8(pu1_cur_row)))
    AND         v26.16b,  v26.16b ,  v1.16b //II edge_idx = vandq_s8(edge_idx, au1_mask)

    SUB         v3.16b,  v18.16b ,  v3.16b  //III sign_down = vreinterpretq_s8_u8(vsubq_u8(cmp_lt, cmp_gt))
    TBL         v24.16b, {v7.16b},v26.16b   //II offset = vtbl1_s8(offset_tbl, vget_low_s8(edge_idx))
    ADD         v18.16b,  v0.16b ,  v17.16b //III edge_idx = vaddq_s8(const_2, sign_up)

    ADD         v18.16b,  v18.16b ,  v3.16b //III edge_idx = vaddq_s8(edge_idx, sign_down)
//  TBL v25.8b, {v7.16b},v27.8b                    //II offset = vtbl1_s8(offset_tbl, vget_high_s8(edge_idx))
    NEG         v17.16b, v3.16b             //III sign_up = vnegq_s8(sign_down)

    SADDW       v28.8h,  v28.8h ,  v24.8b   //II pi2_tmp_cur_row.val[0] = vaddw_s8(pi2_tmp_cur_row.val[0], offset)
    TBL         v18.16b, {v6.16b},v18.16b   //III vtbl1_s8(edge_idx_tbl, vget_low_s8(edge_idx))
    SMAX        v28.8h,  v28.8h ,  v2.8h    //II pi2_tmp_cur_row.val[0] = vmaxq_s16(pi2_tmp_cur_row.val[0], const_min_clip)

    EXT         v17.16b,  v17.16b ,  v17.16b,#1 //III sign_up = vextq_s8(sign_up, sign_up, 1)
//  TBL v19.8b, {v6.16b},v19.8b                //III vtbl1_s8(edge_idx_tbl, vget_high_s8(edge_idx))
    UMIN        v28.8h,  v28.8h ,  v4.8h    //II pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vminq_u16(vreinterpretq_u16_s16(pi2_tmp_cur_row.val[0]), const_max_clip))

    Uxtl2       v26.8h, v5.16b              //II pi2_tmp_cur_row.val[1] = vreinterpretq_s16_u16(vmovl_u8(vget_high_u8(pu1_cur_row)))
    AND         v18.16b,  v18.16b ,  v1.16b //III edge_idx = vandq_s8(edge_idx, au1_mask)

    SADDW2      v26.8h,  v26.8h ,  v24.16b  //II pi2_tmp_cur_row.val[1] = vaddw_s8(pi2_tmp_cur_row.val[1], offset)
    TBL         v3.16b, {v7.16b},v18.16b    //III offset = vtbl1_s8(offset_tbl, vget_low_s8(edge_idx))
    SMAX        v26.8h,  v26.8h ,  v2.8h    //II pi2_tmp_cur_row.val[1] = vmaxq_s16(pi2_tmp_cur_row.val[1], const_min_clip)

    Uxtl        v20.8h, v16.8b              //III pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vmovl_u8(vget_low_u8(pu1_cur_row)))
    UMIN        v26.8h,  v26.8h ,  v4.8h    //II pi2_tmp_cur_row.val[1] = vreinterpretq_s16_u16(vminq_u16(vreinterpretq_u16_s16(pi2_tmp_cur_row.val[1]), const_max_clip))

    SADDW       v20.8h,  v20.8h ,  v3.8b    //III pi2_tmp_cur_row.val[0] = vaddw_s8(pi2_tmp_cur_row.val[0], offset)
//  TBL v11.8b, {v7.16b},v19.8b                    //III offset = vtbl1_s8(offset_tbl, vget_high_s8(edge_idx))
    SMAX        v20.8h,  v20.8h ,  v2.8h    //III pi2_tmp_cur_row.val[0] = vmaxq_s16(pi2_tmp_cur_row.val[0], const_min_clip)

    Uxtl2       v22.8h, v16.16b             //III pi2_tmp_cur_row.val[1] = vreinterpretq_s16_u16(vmovl_u8(vget_high_u8(pu1_cur_row)))
    UMIN        v20.8h,  v20.8h ,  v4.8h    //III pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vminq_u16(vreinterpretq_u16_s16(pi2_tmp_cur_row.val[0]), const_max_clip))

    xtn         v28.8b,  v28.8h             //II vmovn_s16(pi2_tmp_cur_row.val[0])
    SADDW2      v22.8h,  v22.8h ,  v3.16b   //III pi2_tmp_cur_row.val[1] = vaddw_s8(pi2_tmp_cur_row.val[1], offset)

    xtn2        v28.16b,  v26.8h            //II vmovn_s16(pi2_tmp_cur_row.val[1])
    SMAX        v22.8h,  v22.8h ,  v2.8h    //III pi2_tmp_cur_row.val[1] = vmaxq_s16(pi2_tmp_cur_row.val[1], const_min_clip)

    mov         v5.16b, v30.16b             //II pu1_cur_row = pu1_next_row
    UMIN        v22.8h,  v22.8h ,  v4.8h    //III pi2_tmp_cur_row.val[1] = vreinterpretq_s16_u16(vminq_u16(vreinterpretq_u16_s16(pi2_tmp_cur_row.val[1]), const_max_clip))

    CMP         x7,#1                       //III
    ST1         { v28.16b},[x0],x1          //II vst1q_u8(pu1_src_cpy, pu1_cur_row)
    BGT         PU1_SRC_LOOP                //If not equal jump to PU1_SRC_LOOP
    BLT         INNER_LOOP_DONE

    ADD         x8,x0,x1,LSL #1             //*pu1_src + src_strd
    xtn         v20.8b,  v20.8h             //III vmovn_s16(pi2_tmp_cur_row.val[0])
    MOV         x5,x23                      //Loads pu1_avail

    LDRB        w5,[x5,#3]                  //pu1_avail[3]
    xtn2        v20.16b,  v22.8h            //III vmovn_s16(pi2_tmp_cur_row.val[1])
    CMP         x5,#0

    ADD         x4,x0,x1                    //pu1_src_cpy[16 - src_strd]
    LD1         {v16.16b},[x8]              //pu1_next_row = vld1q_u8(pu1_src_cpy + src_strd)
    LDRB        w5,[x0,#16]                 //load the value

    BEQ         NEXT_ROW_ELSE_3
    SUB         x8,x8,#1
    LDRB        w8,[x8]                     //pu1_src_cpy[src_strd - 1]
    B           NEXT_ROW_POINTER_ASSIGNED_3
NEXT_ROW_ELSE_3:
    SUB         x11,x12,x7                  //ht_tmp - row
    ADD         x8,x14,x11                  //pu1_src_left_cpy[ht_tmp - row]
    ADD         x8,x8,#1                    //pu1_src_left_cpy[ht_tmp - row + 1]
    LDRB        w8,[x8]

NEXT_ROW_POINTER_ASSIGNED_3:
    LDRB        w11,[x4,#15]                //pu1_src_cpy[15]
    mov         v18.b[15], w8               //vsetq_lane_u8
    SUB         x8,x11,x5                   //pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]

    CMP         x8,#0
    EXT         v18.16b,  v18.16b ,  v16.16b,#15 //pu1_next_row_tmp = vextq_u8(pu1_next_row_tmp, pu1_next_row, 15)
    movn        x20,#0
    csel        x8, x20, x8,LT

    ST1         { v20.16b},[x0],x1          //III vst1q_u8(pu1_src_cpy, pu1_cur_row)
    cmhi        v24.16b,  v5.16b ,  v18.16b //vcgtq_u8(pu1_cur_row, pu1_next_row_tmp)

    MOV         x20,#1
    csel        x8, x20, x8,GT              //SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd])
    cmhi        v26.16b,  v18.16b ,  v5.16b //vcltq_u8(pu1_cur_row, pu1_next_row_tmp)

    mov         v17.b[15], w8               //sign_up = vsetq_lane_s8(SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]), sign_up, 15)
    SUB         v24.16b,  v26.16b ,  v24.16b //sign_down = vreinterpretq_s8_u8(vsubq_u8(cmp_lt, cmp_gt))

    Uxtl        v20.8h, v5.8b               //pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vmovl_u8(vget_low_u8(pu1_cur_row)))
    ADD         v26.16b,  v0.16b ,  v17.16b //edge_idx = vaddq_s8(const_2, sign_up)

    Uxtl2       v22.8h, v5.16b              //pi2_tmp_cur_row.val[1] = vreinterpretq_s16_u16(vmovl_u8(vget_high_u8(pu1_cur_row)))
    ADD         v26.16b,  v26.16b ,  v24.16b //edge_idx = vaddq_s8(edge_idx, sign_down)

    TBL         v26.16b, {v6.16b},v26.16b   //vtbl1_s8(edge_idx_tbl, vget_low_s8(edge_idx))
//  TBL v27.8b, {v6.16b},v27.8b                //vtbl1_s8(edge_idx_tbl, vget_high_s8(edge_idx))

    AND         v26.16b,  v26.16b ,  v1.16b //edge_idx = vandq_s8(edge_idx, au1_mask)

    TBL         v24.16b, {v7.16b},v26.16b   //offset = vtbl1_s8(offset_tbl, vget_low_s8(edge_idx))

    SADDW       v20.8h,  v20.8h ,  v24.8b   //pi2_tmp_cur_row.val[0] = vaddw_s8(pi2_tmp_cur_row.val[0], offset)
//  TBL v25.8b, {v7.16b},v27.8b                    //offset = vtbl1_s8(offset_tbl, vget_high_s8(edge_idx))
    SMAX        v20.8h,  v20.8h ,  v2.8h    //pi2_tmp_cur_row.val[0] = vmaxq_s16(pi2_tmp_cur_row.val[0], const_min_clip)

    UMIN        v20.8h,  v20.8h ,  v4.8h    //pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vminq_u16(vreinterpretq_u16_s16(pi2_tmp_cur_row.val[0]), const_max_clip))

    SADDW2      v22.8h,  v22.8h ,  v24.16b  //pi2_tmp_cur_row.val[1] = vaddw_s8(pi2_tmp_cur_row.val[1], offset)
    SMAX        v22.8h,  v22.8h ,  v2.8h    //pi2_tmp_cur_row.val[1] = vmaxq_s16(pi2_tmp_cur_row.val[1], const_min_clip)
    UMIN        v22.8h,  v22.8h ,  v4.8h    //pi2_tmp_cur_row.val[1] = vreinterpretq_s16_u16(vminq_u16(vreinterpretq_u16_s16(pi2_tmp_cur_row.val[1]), const_max_clip))

INNER_LOOP_DONE:
    xtn         v20.8b,  v20.8h             //vmovn_s16(pi2_tmp_cur_row.val[0])
    MOV         x8,x17                      //Loads ht

    xtn2        v20.16b,  v22.8h            //vmovn_s16(pi2_tmp_cur_row.val[1])
    ADD         x5,sp,#0x42                 //*au1_src_left_tmp

    ST1         { v20.16b},[x0],x1          //vst1q_u8(pu1_src_cpy, pu1_cur_row)
    MOV         x2,x21                      //Loads *pu1_src_left
SRC_LEFT_LOOP:
    LDR         w7,[x5],#4                  //au1_src_left_tmp[row]
    SUBS        x8,x8,#4
    STR         w7,[x2],#4                  //pu1_src_left[row] = au1_src_left_tmp[row]
    BNE         SRC_LEFT_LOOP

    SUBS        x6,x6,#16                   //Decrement the wd loop count by 16
    CMP         x6,#8                       //Check whether residue remains
    BLT         RE_ASSINING_LOOP            //Jump to re-assigning loop
    MOV         x7,x16                      //Loads wd
    MOV         x0,x15                      //Loads *pu1_src
    SUB         x7,x7,x6
    ADD         x0,x0,x7
    BGT         WIDTH_LOOP_16               //If not equal jump to width_loop
    BEQ         WIDTH_RESIDUE               //If residue remains jump to residue loop



WD_16_HT_4_LOOP:
    MOV         x5,x23                      //Loads pu1_avail
    MOV         x7,x16                      //Loads wd
    CMP         x6,x7                       //col == wd
    LDRb        w20, [x5]                   //pu1_avail[0]
    csel        w8,w20,w8,EQ
    MOV         x20,#-1
    csel        x8, x20, x8,NE
    mov         v1.b[0], w8                 //au1_mask = vsetq_lane_s8(-1, au1_mask, 0)

    CMP         x6,#16                      //if(col == 16)
    BNE         SKIP_AU1_MASK_VAL_WD_16_HT_4
    LDRB        w8,[x5,#1]                  //pu1_avail[1]
    mov         v1.b[15], w8                //au1_mask = vsetq_lane_s8(pu1_avail[1], au1_mask, 15)

SKIP_AU1_MASK_VAL_WD_16_HT_4:
    LDRB        w8,[x5,#2]                  //pu1_avail[2]
    CMP         x8,#0

    SUB         x20,x0,x1                   //pu1_src - src_strd
    csel        x8, x20, x8,EQ
    csel        x8, x3, x8,NE
    ADD         x8,x8,#1                    //pu1_src - src_strd + 1
    LD1         {v3.16b},[x8]               //pu1_top_row = vld1q_u8(pu1_src - src_strd + 1)

    ADD         x3,x3,#16
    ADD         x5,sp,#0x42                 //*au1_src_left_tmp
    MOV         x4,x17                      //Loads ht
    MOV         x7,x16                      //Loads wd
    SUB         x7,x7,x6                    //(wd - col)
    ADD         x7,x7,#15                   //15 + (wd - col)
    MOV         x8,x19                      //Loads *pu1_src
    ADD         x7,x8,x7                    //pu1_src[0 * src_strd + 15 + (wd - col)]
    SUB         x5,x5,#1

AU1_SRC_LEFT_LOOP_WD_16_HT_4:
    LDRB        w8,[x7]                     //load the value and increment by src_strd
    ADD         x7,x7,x1
    STRB        w8,[x5,#1]!                 //store it in the stack pointer
    SUBS        x4,x4,#1                    //decrement the loop count
    BNE         AU1_SRC_LEFT_LOOP_WD_16_HT_4

    LD1         {v5.16b},[x0]               //pu1_cur_row = vld1q_u8(pu1_src)

    cmhi        v17.16b,  v5.16b ,  v3.16b  //vcgtq_u8(pu1_cur_row, pu1_top_row)
    cmhi        v16.16b,  v3.16b ,  v5.16b  //vcltq_u8(pu1_cur_row, pu1_top_row)
    SUB         v17.16b,  v16.16b ,  v17.16b //sign_up = vreinterpretq_s8_u8(vsubq_u8(cmp_lt, cmp_gt))
    movi        v18.16b, #0
    MOV         x7,x12                      //row count, move ht_tmp to x7

PU1_SRC_LOOP_WD_16_HT_4:
    ADD         x8,x0,x1                    //*pu1_src + src_strd
    LD1         {v16.16b},[x8]              //pu1_next_row = vld1q_u8(pu1_src_cpy + src_strd)
    MOV         x5,x23                      //Loads pu1_avail
    LDRB        w5,[x5,#3]                  //pu1_avail[3]
    CMP         x5,#0
    BEQ         NEXT_ROW_ELSE_WD_16_HT_4
    CMP         x7,#1
    SUB         x8,x8,#1
    LDRb        w20, [x8]                   //pu1_src_cpy[src_strd - 1]
    csel        w8,w20,w8,EQ
    BEQ         NEXT_ROW_POINTER_ASSIGNED_WD_16_HT_4
NEXT_ROW_ELSE_WD_16_HT_4:
    SUB         x5,x12,x7                   //ht_tmp - row
    ADD         x8,x14,x5                   //pu1_src_left_cpy[ht_tmp - row]
    ADD         x8,x8,#1                    //pu1_src_left_cpy[ht_tmp - row + 1]
    LDRB        w8,[x8]

NEXT_ROW_POINTER_ASSIGNED_WD_16_HT_4:
    mov         v18.b[15], w8               //vsetq_lane_u8
    EXT         v18.16b,  v18.16b ,  v16.16b,#15 //pu1_next_row_tmp = vextq_u8(pu1_next_row_tmp, pu1_next_row, 15)

    CMP         x7,x12
    BNE         SIGN_UP_CHANGE_WD_16_HT_4
    MOV         x5,x23                      //Loads pu1_avail
    LDRB        w5,[x5,#2]                  //pu1_avail[2]
    CMP         x5,#0
    BNE         SIGN_UP_CHANGE_DONE_WD_16_HT_4

SIGN_UP_CHANGE_WD_16_HT_4:
    LDRB        w8,[x0,#15]                 //pu1_src_cpy[15]
    ADD         x5,x0,#16                   //pu1_src_cpy[16]
    SUB         x5,x5,x1                    //pu1_src_cpy[16 - src_strd]
    LDRB        w5,[x5]                     //load the value
    SUB         x8,x8,x5                    //pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]
    CMP         x8,#0
    movn        x20,#0
    csel        x8, x20, x8,LT
    MOV         x20,#1
    csel        x8, x20, x8,GT              //SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd])
    mov         v17.b[15], w8               //sign_up = vsetq_lane_s8(SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]), sign_up, 15)

SIGN_UP_CHANGE_DONE_WD_16_HT_4:
    cmhi        v20.16b,  v5.16b ,  v18.16b //vcgtq_u8(pu1_cur_row, pu1_next_row_tmp)
    cmhi        v22.16b,  v18.16b ,  v5.16b //vcltq_u8(pu1_cur_row, pu1_next_row_tmp)
    SUB         v24.16b,  v22.16b ,  v20.16b //sign_down = vreinterpretq_s8_u8(vsubq_u8(cmp_lt, cmp_gt))

    ADD         v26.16b,  v0.16b ,  v17.16b //edge_idx = vaddq_s8(const_2, sign_up)
    ADD         v26.16b,  v26.16b ,  v24.16b //edge_idx = vaddq_s8(edge_idx, sign_down)
    TBL         v26.16b, {v6.16b},v26.16b   //vtbl1_s8(edge_idx_tbl, vget_low_s8(edge_idx))
//  TBL v27.8b, {v6.16b},v27.8b                //vtbl1_s8(edge_idx_tbl, vget_high_s8(edge_idx))

    AND         v26.16b,  v26.16b ,  v1.16b //edge_idx = vandq_s8(edge_idx, au1_mask)

    NEG         v17.16b, v24.16b            //sign_up = vnegq_s8(sign_down)
    EXT         v17.16b,  v17.16b ,  v17.16b,#1 //sign_up = vextq_s8(sign_up, sign_up, 1)

    TBL         v24.16b, {v7.16b},v26.16b   //offset = vtbl1_s8(offset_tbl, vget_low_s8(edge_idx))
    Uxtl        v28.8h, v5.8b               //pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vmovl_u8(vget_low_u8(pu1_cur_row)))
    SADDW       v28.8h,  v28.8h ,  v24.8b   //pi2_tmp_cur_row.val[0] = vaddw_s8(pi2_tmp_cur_row.val[0], offset)
    SMAX        v28.8h,  v28.8h ,  v2.8h    //pi2_tmp_cur_row.val[0] = vmaxq_s16(pi2_tmp_cur_row.val[0], const_min_clip)
    UMIN        v28.8h,  v28.8h ,  v4.8h    //pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vminq_u16(vreinterpretq_u16_s16(pi2_tmp_cur_row.val[0]), const_max_clip))

//  TBL v25.8b, {v7.16b},v27.8b                    //offset = vtbl1_s8(offset_tbl, vget_high_s8(edge_idx))
    Uxtl2       v30.8h, v5.16b              //pi2_tmp_cur_row.val[1] = vreinterpretq_s16_u16(vmovl_u8(vget_high_u8(pu1_cur_row)))
    SADDW2      v30.8h,  v30.8h ,  v24.16b  //pi2_tmp_cur_row.val[1] = vaddw_s8(pi2_tmp_cur_row.val[1], offset)
    SMAX        v30.8h,  v30.8h ,  v2.8h    //pi2_tmp_cur_row.val[1] = vmaxq_s16(pi2_tmp_cur_row.val[1], const_min_clip)
    UMIN        v30.8h,  v30.8h ,  v4.8h    //pi2_tmp_cur_row.val[1] = vreinterpretq_s16_u16(vminq_u16(vreinterpretq_u16_s16(pi2_tmp_cur_row.val[1]), const_max_clip))

    xtn         v28.8b,  v28.8h             //vmovn_s16(pi2_tmp_cur_row.val[0])
    xtn2        v28.16b,  v30.8h            //vmovn_s16(pi2_tmp_cur_row.val[1])

    ST1         { v28.16b},[x0],x1          //vst1q_u8(pu1_src_cpy, pu1_cur_row)

    mov         v5.16b, v16.16b             //pu1_cur_row = pu1_next_row
    SUBS        x7,x7,#1                    //Decrement the ht_tmp loop count by 1
    BNE         PU1_SRC_LOOP_WD_16_HT_4     //If not equal jump to PU1_SRC_LOOP_WD_16_HT_4

    MOV         x8,x17                      //Loads ht
    ADD         x5,sp,#0x42                 //*au1_src_left_tmp
    MOV         x2,x21                      //Loads *pu1_src_left
SRC_LEFT_LOOP_WD_16_HT_4:
    LDR         w7,[x5],#4                  //au1_src_left_tmp[row]
    STR         w7,[x2],#4                  //pu1_src_left[row] = au1_src_left_tmp[row]
    SUBS        x8,x8,#4
    BNE         SRC_LEFT_LOOP_WD_16_HT_4

    SUBS        x6,x6,#16                   //Decrement the wd loop count by 16
    BLE         RE_ASSINING_LOOP            //Jump to re-assigning loop
    MOV         x7,x16                      //Loads wd
    MOV         x0,x15                      //Loads *pu1_src
    SUB         x7,x7,x6
    ADD         x0,x0,x7
    BGT         WD_16_HT_4_LOOP             //If not equal jump to width_loop


WIDTH_RESIDUE:
    MOV         x7,x16                      //Loads wd
    MOV         x5,x23                      //Loads pu1_avail
    CMP         x6,x7                       //wd_residue == wd
    LDRb        w20, [x5]                   //pu1_avail[0]
    csel        w8,w20,w8,EQ

    MOV         x20,#-1
    csel        x8, x20, x8,NE
    mov         v1.b[0], w8                 //au1_mask = vsetq_lane_s8(-1, au1_mask, 0)

    LDRB        w8,[x5,#1]                  //pu1_avail[1]
    mov         v1.b[7], w8                 //au1_mask = vsetq_lane_s8(pu1_avail[1], au1_mask, 15)

PU1_AVAIL_2_RESIDUE:
    LDRB        w8,[x5,#2]                  //pu1_avail[2]
    CMP         x8,#0

    SUB         x20,x0,x1                   //pu1_src - src_strd
    csel        x8, x20, x8,EQ
    csel        x8, x3, x8,NE
    ADD         x8,x8,#1                    //pu1_src - src_strd + 1
    LD1         {v3.16b},[x8]               //pu1_top_row = vld1q_u8(pu1_src - src_strd + 1)


    ADD         x5,sp,#0x42                 //*au1_src_left_tmp
    MOV         x4,x17                      //Loads ht
    MOV         x7,x16                      //Loads wd
    MOV         x8,x19                      //Loads *pu1_src
    SUB         x7,x7,#1                    //(wd - 1)
    ADD         x7,x8,x7                    //pu1_src[0 * src_strd + (wd - 1)]
    SUB         x5,x5,#1

AU1_SRC_LEFT_LOOP_RESIDUE:
    LDRB        w8,[x7]                     //load the value and increment by src_strd
    ADD         x7,x7,x1
    STRB        w8,[x5,#1]!                 //store it in the stack pointer
    SUBS        x4,x4,#1                    //decrement the loop count
    BNE         AU1_SRC_LEFT_LOOP_RESIDUE

    LD1         {v5.16b},[x0]               //pu1_cur_row = vld1q_u8(pu1_src)

    cmhi        v17.16b,  v5.16b ,  v3.16b  //vcgtq_u8(pu1_cur_row, pu1_top_row)
    cmhi        v16.16b,  v3.16b ,  v5.16b  //vcltq_u8(pu1_cur_row, pu1_top_row)
    SUB         v17.16b,  v16.16b ,  v17.16b //sign_up = vreinterpretq_s8_u8(vsubq_u8(cmp_lt, cmp_gt))
    MOV         x7,x12                      //row count, move ht_tmp to x7

PU1_SRC_LOOP_RESIDUE:
    movi        v18.16b, #0
    ADD         x8,x0,x1                    //*pu1_src + src_strd
    LD1         {v16.16b},[x8]              //pu1_next_row = vld1q_u8(pu1_src_cpy + src_strd)
    MOV         x5,x23                      //Loads pu1_avail
    LDRB        w5,[x5,#3]                  //pu1_avail[3]
    CMP         x5,#0
    BEQ         NEXT_ROW_ELSE_RESIDUE
    CMP         x7,#1
    SUB         x8,x8,#1
    LDRb        w20, [x8]                   //pu1_src_cpy[src_strd - 1]
    csel        w8,w20,w8,EQ
    BEQ         NEXT_ROW_POINTER_ASSIGNED_RESIDUE
NEXT_ROW_ELSE_RESIDUE:
    SUB         x5,x12,x7                   //ht_tmp - row
    ADD         x8,x14,x5                   //pu1_src_left_cpy[ht_tmp - row]
    ADD         x8,x8,#1                    //pu1_src_left_cpy[ht_tmp - row + 1]
    LDRB        w8,[x8]

NEXT_ROW_POINTER_ASSIGNED_RESIDUE:
    mov         v18.b[15], w8               //vsetq_lane_u8
    EXT         v18.16b,  v18.16b ,  v16.16b,#15 //pu1_next_row_tmp = vextq_u8(pu1_next_row_tmp, pu1_next_row, 15)

    CMP         x7,x12
    BNE         SIGN_UP_CHANGE_RESIDUE
    MOV         x5,x23                      //Loads pu1_avail
    LDRB        w5,[x5,#2]                  //pu1_avail[2]
    CMP         x5,#0
    BNE         SIGN_UP_CHANGE_DONE_RESIDUE

SIGN_UP_CHANGE_RESIDUE:
    LDRB        w8,[x0,#15]                 //pu1_src_cpy[15]
    ADD         x5,x0,#16                   //pu1_src_cpy[16]
    SUB         x5,x5,x1                    //pu1_src_cpy[16 - src_strd]
    LDRB        w5,[x5]                     //load the value
    SUB         x8,x8,x5                    //pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]
    CMP         x8,#0
    movn        x20,#0
    csel        x8, x20, x8,LT
    MOV         x20,#1
    csel        x8, x20, x8,GT              //SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd])
    mov         v17.b[15], w8               //sign_up = vsetq_lane_s8(SIGN(pu1_src_cpy[15] - pu1_src_cpy[16 - src_strd]), sign_up, 15)

SIGN_UP_CHANGE_DONE_RESIDUE:
    cmhi        v20.16b,  v5.16b ,  v18.16b //vcgtq_u8(pu1_cur_row, pu1_next_row_tmp)
    cmhi        v22.16b,  v18.16b ,  v5.16b //vcltq_u8(pu1_cur_row, pu1_next_row_tmp)
    SUB         v24.16b,  v22.16b ,  v20.16b //sign_down = vreinterpretq_s8_u8(vsubq_u8(cmp_lt, cmp_gt))

    ADD         v26.16b,  v0.16b ,  v17.16b //edge_idx = vaddq_s8(const_2, sign_up)
    ADD         v26.16b,  v26.16b ,  v24.16b //edge_idx = vaddq_s8(edge_idx, sign_down)
    TBL         v26.16b, {v6.16b},v26.16b   //vtbl1_s8(edge_idx_tbl, vget_low_s8(edge_idx))
//  TBL v27.8b, {v6.16b},v27.8b                //vtbl1_s8(edge_idx_tbl, vget_high_s8(edge_idx))

    AND         v26.16b,  v26.16b ,  v1.16b //edge_idx = vandq_s8(edge_idx, au1_mask)

    NEG         v17.16b, v24.16b            //sign_up = vnegq_s8(sign_down)
    EXT         v17.16b,  v17.16b ,  v17.16b,#1 //sign_up = vextq_s8(sign_up, sign_up, 1)

    TBL         v24.8b, {v7.16b},v26.8b     //offset = vtbl1_s8(offset_tbl, vget_low_s8(edge_idx))
    Uxtl        v28.8h, v5.8b               //pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vmovl_u8(vget_low_u8(pu1_cur_row)))
    SADDW       v28.8h,  v28.8h ,  v24.8b   //pi2_tmp_cur_row.val[0] = vaddw_s8(pi2_tmp_cur_row.val[0], offset)
    SMAX        v28.8h,  v28.8h ,  v2.8h    //pi2_tmp_cur_row.val[0] = vmaxq_s16(pi2_tmp_cur_row.val[0], const_min_clip)
    UMIN        v28.8h,  v28.8h ,  v4.8h    //pi2_tmp_cur_row.val[0] = vreinterpretq_s16_u16(vminq_u16(vreinterpretq_u16_s16(pi2_tmp_cur_row.val[0]), const_max_clip))

    xtn         v30.8b,  v28.8h             //vmovn_s16(pi2_tmp_cur_row.val[0])

    ST1         {v30.8b},[x0],x1            //vst1q_u8(pu1_src_cpy, pu1_cur_row)
    mov         v5.16b, v16.16b             //pu1_cur_row = pu1_next_row
    SUBS        x7,x7,#1
    BNE         PU1_SRC_LOOP_RESIDUE

    MOV         x8,x17                      //Loads ht
    MOV         x2,x21                      //Loads *pu1_src_left
    ADD         x5,sp,#0x42                 //*au1_src_left_tmp

SRC_LEFT_LOOP_RESIDUE:
    LDR         w7,[x5],#4                  //au1_src_left_tmp[row]
    SUBS        x8,x8,#4
    STR         w7,[x2],#4                  //pu1_src_left[row] = au1_src_left_tmp[row]
    BNE         SRC_LEFT_LOOP_RESIDUE


RE_ASSINING_LOOP:
    MOV         x7,x16                      //Loads wd
    MOV         x0,x19                      //Loads *pu1_src

    MOV         x11,x17                     //Loads ht
    ADD         x8,x0,x7                    //pu1_src[wd]

    MOV         x4,x24                      //Loads pu1_src_top_left
    SUB         x11,x11,#1                  //ht - 1

    SUB         x8,x8,#1
    STRB        w9,[x8]                     //pu1_src_org[wd - 1] = u1_pos_wd_0_tmp
    ADD         x8,x8,#1
    madd        x6, x11, x1, x0             //pu1_src_org[(ht - 1) * src_strd]

    LDRB        w8,[sp]                     //load u1_src_top_left_tmp from stack pointer
    ADD         x12,sp,#0x02

    STRB        w10,[x6]                    //pu1_src_org[wd - 1 + (ht - 1) * src_strd] = u1_pos_wd_ht_tmp
    STRB        w8,[x4]                     //*pu1_src_top_left = u1_src_top_left_tmp
    MOV         x3,x22                      //Loads pu1_src_top

SRC_TOP_LOOP:
    LD1         {v0.8b},[x12],#8            //pu1_src_top[col] = au1_src_top_tmp[col]
    SUBS        x7,x7,#8                    //Decrement the width
    ST1         {v0.8b},[x3],#8             //pu1_src_top[col] = au1_src_top_tmp[col]
    BNE         SRC_TOP_LOOP

END_LOOPS:
    ADD         sp,sp,#0xA0
    // LDMFD sp!,{x4-x12,x15}             //Reload the registers from SP
    ldp         x23, x24,[sp], #16
    ldp         x21, x22,[sp], #16
    ldp         x19, x20,[sp], #16
    ret



