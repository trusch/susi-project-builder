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

var ChatController = {
	init: function(){
		susi.events.subscribe("chatmessages",function(evt){
			console.log("Chat Message:",evt.payload);
		});
	},
	chat: function(msg){
		susi.events.publish("chatmessages",msg);
	}
};

ChatController.init();
var chat = ChatController.chat;
