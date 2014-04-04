var encode_msg_all = "";
var msg_all = "";
var is_stop = 0;

function errorHandler(e) {
    console.log("Error");
    console.dir(e);
}

//demo http://webaudiodemos.appspot.com/AudioRecorder/index.html
function init() {
    if (navigator.webkitGetUserMedia) {

        navigator.webkitGetUserMedia({
            video: true,
            audio: true,
        }, gotStream, noStream);

        var video = document.getElementById('monitor');
        var canvas = document.getElementById('photo');

        function gotStream(stream) {
            init_audio(stream);
            video.src = webkitURL.createObjectURL(stream);
            video.onerror = function() {
                stream.stop();
                streamError();
            };
            document.getElementById('splash').hidden = true;
            document.getElementById('app').hidden = false;
            $("#stop_btn").click(stop_record);
            $("#stop_btn").attr('disabled', true);
            $("#record_video_btn").click(record_video);
        }

        function noStream() {
            document.getElementById('errorMessage').textContent = 'No camera available.';
        }

        function streamError() {
            document.getElementById('errorMessage').textContent = 'Camera error.';
        }

        function stop_record() {
            is_stop = 1;
        }

        function getFrameData() {
            canvas.width = video.videoWidth;
            canvas.height = video.videoHeight;
            var context = canvas.getContext('2d');
            context.drawImage(video, 0, 0);
            var imageData = context.getImageData(0, 0, canvas.width, canvas.height);
            var data = imageData.data;
            var grayData = new Uint8Array(data.length / 4);

            for (var i = 0; i < data.length; i += 4) {
                var brightness = 0.34 * data[i] + 0.5 * data[i + 1] + 0.16 * data[i + 2];
                // red
                data[i] = brightness;
                // green
                data[i + 1] = brightness;
                // blue
                data[i + 2] = brightness;

                grayData[i / 4] = Math.round(brightness);
                //grayData += String.fromCharCode(brightness);
            }
            // overwrite original image
            context.putImageData(imageData, 0, 0);
            return grayData;
        }

        // return 88B Uint8Array
        function detect_one_frame(grayData) {
            var msg;
            var data;
            msg = Module.webTrackerDetect(canvas.width, canvas.height, canvas.width, 1, 0, grayData);
            data = $.base64.decode(msg);
            return data;
        }

        //record 15s or user click stop
        function record_video() {
            var i = 0;
            var fps = 30; // fixed = 50
            var sec = 15; // fixed = 15
            var interval = 1000 / fps; // ms
            var num_frames = fps * sec;

            //clean msg
            encode_msg_all = "";
            msg_all = "";

            //clear stop bit
            is_stop = 0;

            var dataImgs = new Array(num_frames);

            // disable start,enable stop
            $("#record_video_btn").attr('disabled', true);
            $("#stop_btn").attr('disabled', false);
            var start = new Date().getTime();
            Module.webTrackerCreate();

            //record audio
            audioRecorder.clear();
            audioRecorder.record();

            var timerId = setInterval(function() {
                // var start1 = new Date().getTime();
                //msg_all += detect_one_frame(getFrameData());; // 50ms
                dataImgs[i] = getFrameData();
                // console.log('detect time: ' + (new Date().getTime() - start1));
                i += 1;
                if (i >= num_frames || is_stop) {
                    // stop timer
                    clearInterval(timerId);

                    // stop record audio
                    audioRecorder.stop();
                    console.log('real time(15s): ' + (new Date().getTime() - start));

                    // detect all imags
                    start = new Date().getTime();
                    var j = 0;
                    for (; j < num_frames; j++) {
                        msg_all += detect_one_frame(dataImgs[j]);; // 50ms
                    }
                    console.log('detect time: ' + (new Date().getTime() - start));
                    audioRecorder.getBuffers(gotBuffers);
                    Module.webTrackerRelease();
                    $("#record_video_btn").attr('disabled', false);
                    $("#stop_btn").attr('disabled', true);
                }
            }, interval);
        }

        function stop_record() {
            is_stop = 1;
        }
    } else {
        document.getElementById('errorMessage').textContent = 'No native camera support available.';
    }
}