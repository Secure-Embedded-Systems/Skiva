unsigned char key[16] = {
0x7b, 0x64, 0xdd, 0x3c, 0x4c, 0x02, 0x17, 0x80, 0x8b, 0xf8, 0x6f, 0x16, 0xc1, 0xe4, 0x13, 0x9e };
unsigned char input[16*32] = {
0xc1, 0x8a, 0x37, 0x43, 0x14, 0x51, 0xbd, 0x79, 0xdf, 0xc0, 0xd0, 0x0e, 0x55, 0xe6, 0x72, 0xae,
0xe0, 0xac, 0xa4, 0x74, 0x85, 0x0a, 0xf2, 0x84, 0xed, 0xbd, 0xac, 0xef, 0x3b, 0x20, 0xf7, 0xa9,
0x72, 0xc8, 0xe4, 0x60, 0x7c, 0x71, 0xe9, 0xa7, 0x60, 0x2a, 0x40, 0x25, 0xf4, 0xad, 0x29, 0x23,
0xb8, 0xa8, 0x90, 0xe5, 0xe9, 0xe1, 0x39, 0xca, 0xf1, 0xd5, 0x02, 0x12, 0x3d, 0x00, 0x25, 0xac,
0x89, 0xf6, 0x13, 0xbe, 0xc0, 0xc7, 0xa3, 0xcc, 0x65, 0x04, 0x29, 0xbf, 0xe0, 0x65, 0xbe, 0x72,
0x3e, 0x3b, 0x83, 0xfc, 0x85, 0xcb, 0x5d, 0xf3, 0x6a, 0xd4, 0xfb, 0x06, 0x7d, 0x7a, 0x95, 0x7c,
0xbc, 0xe9, 0xd3, 0x23, 0x7a, 0xd7, 0x87, 0xa3, 0x2a, 0x47, 0xd3, 0x36, 0xed, 0x86, 0x77, 0x63,
0x0b, 0xd8, 0x16, 0x1b, 0xa7, 0xfe, 0xe7, 0x73, 0x95, 0xa0, 0x56, 0x57, 0x0e, 0xb9, 0xc3, 0xdd,
0x2a, 0xe6, 0xc2, 0x2a, 0x3b, 0x6e, 0x23, 0x09, 0xb6, 0xc1, 0x58, 0x88, 0x22, 0xb6, 0x9c, 0x8f,
0x09, 0xa3, 0x2c, 0x9d, 0xff, 0xf8, 0x02, 0x57, 0xa0, 0xa4, 0x4b, 0x20, 0x20, 0x02, 0x2a, 0xf0,
0xd9, 0x24, 0xb3, 0xdd, 0xe2, 0xd7, 0x7e, 0x20, 0xbe, 0x33, 0x54, 0x87, 0x82, 0x26, 0x3b, 0x38,
0x20, 0x7e, 0x4e, 0x1e, 0xcd, 0xbc, 0xa2, 0xe2, 0x92, 0x01, 0x4a, 0xfd, 0x81, 0xab, 0xf1, 0x9f,
0x3b, 0x78, 0x6a, 0xd3, 0x48, 0x4b, 0x81, 0x8a, 0x34, 0xba, 0x48, 0xb1, 0xd4, 0x3e, 0x66, 0x67,
0x38, 0x70, 0x5f, 0x9a, 0xa7, 0x8e, 0xc9, 0x89, 0x18, 0x45, 0x9a, 0xec, 0x4a, 0x9c, 0x5f, 0x80,
0x3e, 0x98, 0xdd, 0x5d, 0xbe, 0x0e, 0xb6, 0x3d, 0xf3, 0xf0, 0x1f, 0x31, 0xe1, 0x1b, 0x7b, 0xb4,
0xeb, 0xea, 0x14, 0xc3, 0x55, 0x95, 0x6a, 0xbf, 0xb8, 0x1f, 0x71, 0x8d, 0x40, 0xe9, 0x87, 0xae,
0x54, 0x8a, 0x88, 0x3a, 0xe3, 0xc0, 0xed, 0x77, 0x16, 0x53, 0x6e, 0x87, 0x9a, 0x5e, 0xd3, 0x50,
0x92, 0x74, 0xbf, 0x31, 0x41, 0xf4, 0x65, 0x26, 0xe8, 0x93, 0xf0, 0x55, 0x72, 0xf7, 0xb1, 0x20,
0x11, 0xa9, 0x4b, 0x52, 0x54, 0x57, 0x36, 0x3a, 0x76, 0x6c, 0xd3, 0x5e, 0xc5, 0xce, 0x84, 0xc9,
0x06, 0x38, 0xdd, 0xcd, 0xfb, 0xd2, 0x25, 0x8d, 0x8d, 0x35, 0x90, 0x23, 0x87, 0xb6, 0x03, 0xf5,
0xbd, 0xd6, 0x55, 0xfe, 0xa4, 0x55, 0xba, 0xf7, 0xc1, 0x36, 0x0e, 0x09, 0x8e, 0x43, 0x93, 0x00,
0xad, 0xec, 0x02, 0x10, 0x57, 0xd1, 0x59, 0x50, 0x59, 0xe0, 0x7b, 0xbf, 0x3e, 0x67, 0xe3, 0x3d,
0x78, 0x3f, 0x9b, 0x56, 0x35, 0xa6, 0xf7, 0xc1, 0xc6, 0x46, 0x3c, 0x21, 0x9c, 0x6e, 0x25, 0xe0,
0x4f, 0xa2, 0x80, 0x84, 0x97, 0x7b, 0x47, 0x8a, 0x97, 0x6d, 0x54, 0xca, 0xa7, 0x7d, 0x98, 0xb6,
0x5d, 0x52, 0x62, 0x07, 0x60, 0xb6, 0xcf, 0x9e, 0x5a, 0x37, 0xc8, 0xdb, 0x0c, 0xe8, 0x31, 0x47,
0x2a, 0xf3, 0x66, 0x11, 0x30, 0x1a, 0x41, 0xa8, 0xd1, 0xf1, 0xe7, 0x89, 0x95, 0xff, 0xa9, 0x06,
0x28, 0x47, 0x4e, 0x36, 0x76, 0x30, 0xfe, 0x75, 0x68, 0xd2, 0x7f, 0x7c, 0xf2, 0x19, 0x2b, 0xad,
0xcb, 0x10, 0x4a, 0x92, 0xa7, 0x87, 0xb3, 0xca, 0xe5, 0xf3, 0x4e, 0x24, 0xbb, 0x0e, 0x76, 0xec,
0xe8, 0xcf, 0x80, 0xe9, 0x10, 0xf6, 0x62, 0x12, 0xa4, 0x7d, 0x5c, 0x77, 0xbd, 0x68, 0x2d, 0x01,
0x36, 0x31, 0x5e, 0x32, 0xfc, 0x65, 0x51, 0x89, 0xf8, 0x2e, 0xf8, 0xcb, 0x04, 0xea, 0x94, 0xeb,
0x32, 0x6b, 0x49, 0x79, 0x3b, 0xc8, 0xad, 0xbf, 0x62, 0x63, 0x7c, 0xba, 0x20, 0x45, 0x1e, 0x42,
0xc2, 0xe4, 0x51, 0x16, 0x2d, 0x52, 0xe2, 0x90, 0xd2, 0x49, 0x2b, 0x42, 0xa4, 0x16, 0x5d, 0xef };
unsigned char output_ref[16*32] = {
0x1d, 0xa2, 0x1e, 0x72, 0x10, 0xd8, 0xa7, 0x32, 0x04, 0xe2, 0x5b, 0x31, 0xbd, 0x1f, 0x8d, 0x36,
0x41, 0xa8, 0x5b, 0xfd, 0xb1, 0x0e, 0x5a, 0x9a, 0x62, 0x8a, 0x00, 0x4b, 0x43, 0xf2, 0x01, 0x94,
0x03, 0x9e, 0xc5, 0xca, 0xaa, 0x60, 0x2a, 0xe2, 0x79, 0x50, 0x70, 0xab, 0x9d, 0x9a, 0x27, 0x0e,
0xf7, 0x71, 0xef, 0x09, 0xb8, 0xef, 0x24, 0xe1, 0xe2, 0xb2, 0xdc, 0x78, 0x76, 0x91, 0xea, 0xd8,
0xcb, 0xba, 0x30, 0xca, 0xc3, 0x85, 0x81, 0x3f, 0x39, 0x31, 0x0d, 0x55, 0x01, 0xfc, 0x24, 0xa8,
0xd6, 0xd2, 0x56, 0x8e, 0xf4, 0x66, 0x90, 0x13, 0xcd, 0xaa, 0x17, 0xad, 0x43, 0x76, 0xc5, 0xf9,
0xf1, 0x0d, 0x02, 0x39, 0x26, 0xb5, 0xeb, 0xa8, 0x0f, 0xbc, 0x4c, 0x5a, 0xad, 0x97, 0xd6, 0xc5,
0xd0, 0x63, 0xf8, 0xb4, 0xfc, 0xca, 0x32, 0x48, 0xe8, 0xa2, 0x8a, 0xba, 0x2a, 0xa6, 0x7c, 0xf3,
0xe3, 0x65, 0xa6, 0x69, 0x97, 0x95, 0xd2, 0x20, 0xd8, 0x08, 0x6b, 0x86, 0x0f, 0xf0, 0x64, 0xbd,
0x2c, 0x29, 0x8f, 0x15, 0x01, 0xe3, 0x98, 0x46, 0x03, 0xcb, 0xb5, 0xb8, 0x96, 0xec, 0x42, 0xf5,
0x0f, 0xa5, 0xa3, 0x18, 0xa3, 0x8d, 0xee, 0x57, 0xf5, 0xb9, 0x40, 0x29, 0x79, 0x76, 0xf2, 0x01,
0xb5, 0x06, 0x2e, 0x40, 0xf7, 0x7a, 0x8c, 0x02, 0x91, 0xa1, 0x19, 0x3d, 0x05, 0x8f, 0x3e, 0x6b,
0x3a, 0x7c, 0x5d, 0x4a, 0x68, 0x76, 0x28, 0xba, 0x15, 0xeb, 0x99, 0x5a, 0x06, 0x93, 0x3f, 0xcb,
0xb9, 0xe5, 0x8e, 0xdb, 0xce, 0x03, 0x17, 0xcb, 0xa7, 0x6f, 0x71, 0x6d, 0x96, 0x3c, 0x21, 0x78,
0xc1, 0xfb, 0x2c, 0x14, 0x0d, 0x2e, 0xc5, 0x8f, 0x3f, 0x71, 0xc2, 0xcb, 0xf9, 0x08, 0x64, 0x73,
0xa6, 0x55, 0x50, 0xc3, 0x7c, 0xfa, 0x03, 0x26, 0x1a, 0x92, 0x79, 0x53, 0xf9, 0x2e, 0xcd, 0x16,
0xcf, 0x90, 0x21, 0xfd, 0xcf, 0x07, 0x93, 0x72, 0x33, 0x0e, 0x01, 0x57, 0x41, 0x12, 0x0b, 0x7a,
0x0a, 0x4c, 0x1b, 0xbe, 0xb6, 0x6e, 0xb8, 0x05, 0xdc, 0x96, 0x76, 0xac, 0xc3, 0x57, 0x51, 0xbf,
0x98, 0xb8, 0x66, 0x52, 0x39, 0x2b, 0x9e, 0x90, 0xb3, 0x02, 0x6d, 0x1d, 0x6c, 0x8c, 0xc9, 0x3c,
0x13, 0xc4, 0xe9, 0xaf, 0x5f, 0x5f, 0x07, 0x00, 0xbc, 0xe4, 0x0b, 0xb4, 0x19, 0x1e, 0x1e, 0xc9,
0x4d, 0xcf, 0xe7, 0xa7, 0xec, 0xb3, 0xd6, 0xe0, 0x61, 0x51, 0x6d, 0xe1, 0x8b, 0x46, 0x6b, 0x7a,
0xa5, 0x71, 0x37, 0xd9, 0xbf, 0x68, 0x19, 0x20, 0x0f, 0x4d, 0x1c, 0x77, 0xb6, 0x3d, 0xe2, 0xb7,
0xdc, 0xd7, 0xd3, 0x3b, 0x0c, 0x26, 0x27, 0x32, 0xb8, 0x38, 0x87, 0xab, 0x74, 0x99, 0xc1, 0x31,
0xb1, 0x27, 0x70, 0x1d, 0x1b, 0xe3, 0x2b, 0xfc, 0x3d, 0xb1, 0xe9, 0x16, 0x90, 0x31, 0x36, 0xa8,
0xbd, 0x81, 0xdd, 0xd3, 0xf9, 0xd5, 0x72, 0x39, 0x04, 0x7e, 0x4b, 0x9c, 0x13, 0x41, 0x89, 0x4f,
0x8f, 0xb3, 0x58, 0x1a, 0x8e, 0x74, 0xbc, 0x46, 0x82, 0x86, 0x75, 0xf4, 0xd7, 0x0e, 0xb7, 0x01,
0x30, 0x22, 0xf0, 0xbd, 0xe4, 0x8f, 0x6b, 0x83, 0x89, 0x80, 0xd1, 0xae, 0xf4, 0xdb, 0xed, 0x2c,
0xa9, 0x30, 0xbd, 0x88, 0x9f, 0x5a, 0xbb, 0x86, 0x0e, 0x93, 0x96, 0xa8, 0x70, 0x83, 0xa9, 0x89,
0x9e, 0x4f, 0x7d, 0xa5, 0xf4, 0x5b, 0x79, 0x66, 0xc7, 0xc1, 0xf6, 0xca, 0xa5, 0x22, 0x59, 0x79,
0xba, 0x24, 0x60, 0x33, 0x18, 0xaa, 0x15, 0x0a, 0x6f, 0x11, 0x17, 0x66, 0xfb, 0x13, 0xbd, 0x10,
0x23, 0xf8, 0x1d, 0x4c, 0xc1, 0xaa, 0x00, 0xc7, 0x4e, 0x77, 0x45, 0xb9, 0xa1, 0x07, 0x75, 0xf2,
0xfb, 0x59, 0xb2, 0x4f, 0x02, 0x20, 0x91, 0x40, 0x44, 0xb9, 0x12, 0x77, 0xb7, 0x91, 0xb5, 0x86 };