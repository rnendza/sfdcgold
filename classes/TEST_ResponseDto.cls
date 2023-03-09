@isTest
private class TEST_ResponseDto {
    /**
     * (1) DTO 0 arg constructor. success is initialized to false.
     * (2) DTO 2 arg constructor. (boolean, string) stores string msg properly
     */
    @isTest static void testResponseDtoInstantiation() {
        Test.startTest();
        //===(1) DTO success is initialized to false.
        system.assert(!new ResponseDto().isSuccess);
        system.assert(new ResponseDto().sObj == null);

        String msg = 'rockon';
        //===(2) DTO boolean, string constructor stores string msg properly
        system.assert(new ResponseDto(true,msg).message == msg);
        system.assert(new ResponseDto(true,msg).isSuccess);

        Test.stopTest();
    }
}