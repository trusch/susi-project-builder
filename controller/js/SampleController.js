/*
 * Copyright (c) 2014, webvariants GmbH, http://www.webvariants.de
 *
 * This file is released under the terms of the MIT license. You can find the
 * complete text in the attached LICENSE file or online at:
 *
 * http://www.opensource.org/licenses/mit-license.php
 * 
 * @author: Tino Rusch (tino.rusch@webvariants.de)
 */


var SampleController = {
    init: function(){
        susi.events.subscribe("controller::sample",SampleController.awnser);
    },
        
    awnser: function(req){
        susi.events.publish(req.returnaddr,req,0,resultTopic);
    }
}

SampleController.init();
