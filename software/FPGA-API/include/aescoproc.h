#ifndef AESCOPROC_H
#define AESCOPROC_H

void     aes_set_key        (unsigned key[4]);
void     aes_set_input_data (unsigned data[4]);
void     aes_set_iv         (unsigned data[4]);
void     aes_encrypt_ecb    ();
void     aes_decrypt_ecb    ();
void     aes_encrypt_cbc    ();
void     aes_decrypt_cbc    ();
void     aes_get_output_data(unsigned data[4]);
void     aes_soft_reset     ();

#endif
