@isTest
private class TEST_SelectItem {

    @isTest static void testSelectItem() {
        Test.startTest();
        String stringVal = 'stringVal';String stringLabel = 'stringLabel';

        Accel_SelectItem selectItem = new Accel_SelectItem(stringVal,stringLabel);
        system.assert(!selectItem.selected && selectItem.label == stringLabel && selectItem.value == stringVal);

        selectItem = new Accel_SelectItem(stringVal,stringLabel,true);
        system.assert(selectItem.selected && selectItem.label == stringLabel && selectItem.value == stringVal);

        Test.stopTest();
    }
}