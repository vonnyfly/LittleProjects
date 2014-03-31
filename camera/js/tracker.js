function errorHandler(e) {
    console.log("Error");
    console.dir(e);
}

//demo http://webaudiodemos.appspot.com/AudioRecorder/index.html
function init() {
    if (navigator.webkitGetUserMedia) {

        navigator.webkitGetUserMedia({
            video: true,
            audio: true
        }, gotStream, noStream);

        var video = document.getElementById('monitor');
        var canvas = document.getElementById('photo');

        function gotStream(stream) {
            video.src = webkitURL.createObjectURL(stream);
            video.onerror = function() {
                stream.stop();
                streamError();
            };
            init_audio(stream);

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


        var imgs = "";
        var is_stop = 0;

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
            var encode_msg_all = "";
            var msg_all = "";
            is_stop = 0;

            // var dataImgs = new Array(num_frames);

            // disable start,enable stop
            $("#record_video_btn").attr('disabled', true);
            $("#stop_btn").attr('disabled', false);
            var start = new Date().getTime();
            Module.webTrackerCreate();

            //record audio
            audioRecorder.clear();
            audioRecorder.record();

            var timerId = setInterval(function() {
                i += 1;
                // var start1 = new Date().getTime();
                msg_all += detect_one_frame(getFrameData());; // 50ms
                // console.log('detect time: ' + (new Date().getTime() - start1));

                if (i >= num_frames || is_stop) {
                    // NOTE: ajax request
                    // stop record audio
                    audioRecorder.stop();
                    audioRecorder.getBuffers(gotBuffers);

                    // stop timer
                    clearInterval(timerId);
                    Module.webTrackerRelease();
                    console.log('Execution time: ' + (new Date().getTime() - start));
                    // prepare submit form data

                    // detect all imags
                    // var j = 0;
                    // for (; j < num_frames; j++) {
                    //     msg_all += detect_one_frame(dataImgs[j]);; // 50ms
                    // }
                    var formdata = new FormData();
                    encode_msg_all = $.base64.encode(msg_all);
                    console.log(encode_msg_all.length);
                    formdata.append("fmx", encode_msg_all);
                    //formdata.append("irsb", msg);
                    //formdata.append("atm", "int_dawei.atm"); 
                    console.log("submit data");
                    $.ajax({
                        url: 'http://parender-01.bj.intel.com/fengli/camera/request.php',
                        data: formdata,
                        cache: false,
                        contentType: false,
                        processData: false,
                        type: 'POST',
                        success: function(data) {
                            //alert("success");
                            handleResult(data);
                        },
                        error: function() {
                            alert("error");
                        }
                    });
                    console.log('Elapsed time: ' + (new Date().getTime() - start));
                    $("#record_video_btn").attr('disabled', false);
                    $("#stop_btn").attr('disabled', true);
                }
            }, interval);
        }

        function stop_record() {
            is_stop = 1;
        }

        function handleResult(data) {
            if (data.indexOf("http://") == 0) {
                //window.open(data, '_blank');
                $("#result").html(
                    '<video width="480" height="854" controls autoplay>' +
                    '<source src="' + data + '" type="video/mp4"></source>' +
                    '</video>');
                // see here http://stackoverflow.com/questions/6682451/jquery-animate-scroll-to-id-on-page-load
                $("html, body").animate({
                    scrollTop: $('#result').offset().top
                }, 1000);
            } else {
                alert(data);
            }
        }
    } else {
        document.getElementById('errorMessage').textContent = 'No native camera support available.';
    }
}