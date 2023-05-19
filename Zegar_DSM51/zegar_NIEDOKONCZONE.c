#include <at89s8252.h>

#define TRUE 1
#define FALSE 0
#define T0_DAT 65535-921
#define TL_0 T0_DAT%256
#define TH_0 T0_DAT/256

__bit __at (0x95) BUZZ;
__bit __at (0x96) SEG_OFF;
__bit __at (0x97) TEST;
__bit timer_flag;
__bit t0_flag;
	  
__code unsigned char WZOR[10] = { 0b0111111, 0b0000110, 0b1011011, 0b1001111,
 0b1100110, 0b1101101, 0b1111101, 0b0000111, 0b1111111, 0b1101111 };
 
unsigned char ZEGAR[6] = {0, 5, 9, 5, 3, 2};     //od konca (S, S, M, M, G, G)
unsigned char KEYS[4];

unsigned short timer_buf;

void t0_serv(void);
void przelicz();
void key_serv();

void main()
{
    __xdata unsigned char * CSDS = (__xdata unsigned char * ) 0xFF30;
    __xdata unsigned char * CSDB = (__xdata unsigned char * ) 0xFF38;
    unsigned char led_p, led_b;
    SEG_OFF = 0;

    P1_6 = 1;

    PCON = 0x80;
    TMOD = 0b00000001;
    TCON = 0;

    TL0 = TL_0;
    TH0 = TH_0;

    timer_buf  = 996;	//996 dziala najlepiej na sprzecie
    timer_flag = FALSE;
    t0_flag    = FALSE;

    ET0 = TRUE;
    EA  = TRUE;
    TR0 = TRUE;

    while(1){
        for(led_p = 0, led_b = 1; led_p < 6; led_p++, led_b += led_b){
	    SEG_OFF = 1;
	    *CSDS = led_b;
	    *CSDB = WZOR[ZEGAR[led_p]];
	    if( P3_5 == 1 ){
	    	KEYS[0] = KEYS[0] | led_b;
	    }
	    SEG_OFF = 0;
        }
        if(KEYS[0] == KEYS[1] && KEYS[0] == KEYS[2] && KEYS[0] != KEYS[3]){	//czy stabilna
    	   key_serv();
	}
 	KEYS[3] = KEYS[2];
  	KEYS[2] = KEYS[1];
   	KEYS[1] = KEYS[0];
   	KEYS[0] = 0;

   	if( t0_flag ){
            	t0_flag = FALSE;
       	    	t0_serv();
       	    	key_serv();
            }
        if( timer_flag ){        //tu jestem co sekunde
   	    timer_flag = FALSE;
   	    ZEGAR[0]++;
       	    przelicz();
        }
    }
}

void t0_serv(){
    if( timer_buf ) timer_buf--;
    else{
        timer_flag = TRUE;
        timer_buf  = 996; //996 dziala najlepiej na sprzecie
    }

}

void przelicz(){
    if(ZEGAR[0] == 10){
        ZEGAR[0] = 0;
        ZEGAR[1]++;
    }
    if(ZEGAR[1] == 6){
        ZEGAR[1] = 0;
        ZEGAR[2]++;
    }
    if(ZEGAR[2] == 10){
        ZEGAR[2] = 0;
        ZEGAR[3]++;
    }
    if(ZEGAR[3] == 6){
        ZEGAR[3] = 0;
        ZEGAR[4]++;
    }
    if(ZEGAR[4] == 10){
        ZEGAR[4] = 0;
        ZEGAR[5]++;
    }
    if(ZEGAR[5] == 2 && ZEGAR[4] == 4){
        ZEGAR[5] = 0;
        ZEGAR[4] = 0;
    }
}

void key_serv(){
	if(KEYS[0] == 0b100010){
 	    ZEGAR[4]++;
	} else
	if(KEYS[0] == 0b100001){
	    if(ZEGAR[4] == 0){
   		if(ZEGAR[5] == 0){
	    	    ZEGAR[4] = 3;
	    	    ZEGAR[5] = 2;
	        } else {
		    ZEGAR[4] = 9;
		    ZEGAR[5]--;
	        }
	    } else {
	    	ZEGAR[4]--;
 	    }
	} else
	if(KEYS[0] == 0b10010){
 	    ZEGAR[2]++;
	} else
	if(KEYS[0] == 0b10001){
 	    if(ZEGAR[2] == 0){
   		if(ZEGAR[3] == 0){
	    	    ZEGAR[2] = 9;
	    	    ZEGAR[3] = 5;
	        } else {
		    ZEGAR[2] = 9;
		    ZEGAR[3]--;
	        }
	    } else {
	    	ZEGAR[2]--;
 	    }
	} else
	if(KEYS[0] == 0b110){
 	    ZEGAR[0]++;
	} else
	if(KEYS[0] == 0b101){
 	    if(ZEGAR[0] == 0){
   		if(ZEGAR[1] == 0){
	    	    ZEGAR[0] = 9;
	    	    ZEGAR[1] = 5;
	        } else {
		    ZEGAR[0] = 9;
		    ZEGAR[1]--;
	        }
	    } else {
	    	ZEGAR[0]--;
 	    }
	} else
	if(KEYS[0] == 0b1000){
 	    ZEGAR[0] = 0;
 	    ZEGAR[1] = 0;
	}
	przelicz();

}

void t0_int(void) __interrupt(1){

    TL0 = TL0 + TL_0;
    TH0 = TH_0;
    t0_flag = TRUE;
}