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

var susi = {
	internal : {
		sendPostMessage: function(url,data,callback,errorcallback){
			callback = callback || function(){};
			errorcallback = errorcallback || function(){};
			var xmlhttp;
			if (window.XMLHttpRequest) {// code for IE7+, Firefox, Chrome, Opera, Safari
				xmlhttp = new XMLHttpRequest();
			}else{// code for IE6, IE5
				xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
			}
			xmlhttp.onreadystatechange=function(){
				if (xmlhttp.readyState==4){
					if (xmlhttp.status == 200) {
						if (callback !== undefined) {
							callback(xmlhttp.response,200)
						}
					}else{
						if (errorcallback !== undefined) {
							errorcallback(xmlhttp.response,xmlhttp.status)
						}
					}
				}
			};
			xmlhttp.open("POST",url,true);
			xmlhttp.send(JSON.stringify(data));
		},

		log: function(data){
			console.log(data)
		},

		now: Date.now || function(){
			return (new Date()).getTime();
		},

		objectIsEmpty: function(obj){
			for(var key in obj) {
				if (obj.hasOwnProperty(key)) {
					return false;
				}
			}
			return true;
		},
	},

	auth: {
		login: function(username,password){
			var onSuccess = function(){
				console.log("successfully logged in as "+username)
			}
			var onError = function(){
				console.log("failed logging in as "+username)
			} 
			susi.internal.sendPostMessage("/auth/login",{username: username,password: password},
				onSuccess,
				onError);
		},

		logout: function() {
			susi.internal.sendPostMessage("/auth/logout");	
		},

		keepAlive: function(){
			susi.internal.sendPostMessage("/auth/keepalive");	
		},

		info: function(){
			susi.internal.sendPostMessage("/auth/info",null,susi.internal.log);	
		},

	},

	events: {

		subscriptions: {},

		publish: function(key,data,authlevel,returnaddr){
			authlevel = authlevel || 0
			var msg = {
				key: key,
				payload: data,
				authlevel: authlevel,
				returnaddr: returnaddr
			}
			susi.internal.sendPostMessage("/events/publish",msg)
		},
		subscribe: function(key,callback,authlevel){
			authlevel = authlevel || 0;
			var msg = {
				key: key,
				authlevel: authlevel
			};
			susi.events.subscriptions[key] = susi.events.subscriptions[key] || {};
			var id = susi.internal.now();
			susi.events.subscriptions[key][id] = callback;
			susi.internal.sendPostMessage("/events/subscribe",msg);
			return id;
		},
		unsubscribe: function(key,id){
			delete(susi.events.subscriptions[key][id]);
			if(susi.internal.objectIsEmpty(susi.events.subscriptions[key])){
				delete(susi.events.subscriptions[key]);
				susi.internal.sendPostMessage("/events/unsubscribe",{key: key});
			}
		},
		get: function(){
			susi.internal.sendPostMessage("/events/get",null,function(result){
				result = JSON.parse(result);
				if (result !== null) {
					for (var i = result.length - 1; i >= 0; i--) {
						var evt = result[i];
						var callbacks = susi.events.subscriptions[evt.topic];
						if (callbacks != null ){
							for (var key in callbacks) {
								if (callbacks.hasOwnProperty(key)) {
									callbacks[key](evt);
								}
							}
						}
					}
				}
			});
		},

		request: function(topic,payload,callback){
			var self = this;
			var stamp = new Date().getTime().toString();
			var id = susi.events.subscribe(stamp,function(evt){
				callback(evt);
				susi.events.unsubscribe(stamp,id);
			});
			susi.events.publish(topic,payload,0,stamp);
		},
	},
};
