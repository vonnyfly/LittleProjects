<?php 

$video_prefix = '/home/fengli/www-data/camera/video/';
$msg_prefix = '/home/fengli/code/message/';
$newmsg_prefix = '/home/fengli/www-data/camera/newmsg/';
$model_prefix = '/home/fengli/code/model/';

$client = "/home/fengli/code/ndg_iso_pa_avatar_render_server-service/RenderClientNewMain";
$msg = "";
$model = "";
$output = "";
$video_name = "";
$video_path = "";
$result = "";

function random_file($dir = '/tmp/',$suffix = '*')
{
    $files = glob($dir . '*.' . $suffix);
    //print_r($files);
    $file = array_rand($files);
    return $files[$file];
}

/* write video msg  or irsb msg to file*/
function write_binary_file($bytes, $prefix = "", $suffix = "") {
	//global $newmsg_prefix;
	//global $result;
	$filename = $prefix . "." . $suffix;
	if($prefix == ""){
		$filename = uniqid() . "." . $suffix;
		//$zipfile = $filename . ".amx";
	}
	if(!$fp = fopen($filename,"wb")) {
		echo "cann't open file";
		exit;
	}
	$content = base64_decode($bytes);
	//$result .= $content;
	fwrite($fp,$content);
	//fwrite($fp,$bytes);
	fclose($fp);
	return $filename;
}

/* creates a compressed zip file */
function create_zip($files = array(),$destination = '',$overwrite = false) {
	//if the zip file already exists and overwrite is false, return false
	if(file_exists($destination) && !$overwrite) { return false; }
	//vars
	$valid_files = array();
	//if files were passed in...
	if(is_array($files)) {
		//cycle through each file
		foreach($files as $file) {
			//make sure the file exists
			if(file_exists($file)) {
				$valid_files[] = $file;
			}
		}
	}
	//if we have good files...
	if(count($valid_files)) {
		//create the archive
		$zip = new ZipArchive();
		if($zip->open($destination,$overwrite ? ZIPARCHIVE::OVERWRITE : ZIPARCHIVE::CREATE) !== true) {
			return false;
		}
		//add the files
		foreach($valid_files as $file) {
			$zip->addFile($file,$file);
		}
		//debug
		//echo 'The zip archive contains ',$zip->numFiles,' files with a status of ',$zip->status;
		
		//close the zip -- done!
		$zip->close();
		
		//check to make sure the file exists
		return file_exists($destination);
	}
	else
	{
		return false;
	}
}

if($_POST) {
	$files = array();
	chdir($newmsg_prefix);
	$file_pre = uniqid();
	if(array_key_exists('fmx',$_POST)) {
		$filename = write_binary_file($_POST['fmx'], "data", 'fmx');
		array_push($files,$filename);
	}
	if(array_key_exists('irsb',$_POST)) {
		$filename = write_binary_file($_POST['irsb'],$file_pre, 'irsb');
		array_push($files,$filename);
	}

	array_push($files, "data.ilbc");//only for test
	$zipfile = $file_pre . ".amx";
	create_zip($files,$zipfile);

	$msg = " -demux_file " . $newmsg_prefix . $zipfile;
	if(array_key_exists('atm',$_POST)) {
		$model = " -model_file " . $model_prefix . $_POST['atm'];
	}else {
		$model = " -model_file " . random_file($model_prefix,"atm");
	}
	$video_name = $file_pre . ".mp4";
} else {
	// if browser request.php directly , then user random msg and model.
	$msg = " -demux_file " . random_file($msg_prefix,"amx");
	$model = " -model_file " . random_file($model_prefix,"atm");
	$video_name = uniqid() . ".mp4";
}
$video_path =  $video_prefix . $video_name;
$output = " -output_path " . $video_path;
$cmd = $client.$msg.$model.$output; //-ip 172.16.123.28";
$result .= $cmd . "\n";
$result .= shell_exec($cmd);
if(file_exists($video_path)){
	$url = "http://parender-01.bj.intel.com/fengli/camera/video/".$video_name;
	if ($_POST){
		echo $url;
	}else{
		header("Location: $url");
	}
}else{
	echo $result . "\nrender failed";
}
?>