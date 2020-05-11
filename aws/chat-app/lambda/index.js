'use strict';

var AWS = require('aws-sdk');

var S3 = new AWS.S3();
// change to bucket-name you have created.
var bucket = 'lets-chat-neo';

exports.handler = function (event, context, callback) {

    const done = function (err, res) {
        callback(null, {
            statusCode: err ? '400' : '200',
            body: err ? JSON.stringify(err) : JSON.stringify(res),
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        });
    };
    console.log(context);
    S3.getObject({
        Bucket: bucket,
        Key: 'data/conversations.json'
    }, function (err, data) {
        done(err, err ? null : JSON.parse(data.Body.toString()));
    });
};