import os
import unittest
from qcloud_cos import CosConfig, CosS3Client
from dotenv import load_dotenv

load_dotenv()

from utils.other.cos_storage import (
    upload_profile_audio, get_profile_audio_if_exists, upload_additional_profile_audio,
    delete_additional_profile_audio, get_additional_profile_recordings,
    upload_user_person_speech_sample, delete_user_person_speech_sample,
    delete_speech_sample_for_people, delete_user_person_speech_samples,
    get_user_people_ids, get_user_person_speech_samples, upload_postprocessing_audio,
    delete_postprocessing_audio, create_signed_postprocessing_audio_url,
    upload_memory_recording, get_memory_recording_if_exists, delete_all_memory_recordings
)


class TestCosOperationsReal(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # 获取环境变量，初始化 COS 客户端
        secret_id = os.getenv("TENCENT_COS_SECRET_ID")
        secret_key = os.getenv("TENCENT_COS_SECRET_KEY")
        region = os.getenv("TENCENT_COS_REGION")
        token = None  # 如果使用临时密钥，请设置 token

        config = CosConfig(Region=region, SecretId=secret_id, SecretKey=secret_key, Token=token)
        cls.cos_client = CosS3Client(config)

        # 初始化存储桶
        cls.speech_profiles_bucket = os.getenv('BUCKET_SPEECH_PROFILES')

    def test_upload_and_get_profile_audio(self):
        # 创建一个临时文件
        file_path = 'test_audio.wav'
        with open(file_path, 'wb') as f:
            f.write(os.urandom(1024))  # 创建一个 1KB 的随机二进制文件

        uid = '12345'

        # 上传文件
        upload_url = upload_profile_audio(file_path, uid)
        self.assertIn(uid, upload_url)

        # 确认文件存在并下载
        downloaded_path = get_profile_audio_if_exists(uid, download=True)
        self.assertEqual(downloaded_path, f'_temp/{uid}_speech_profile.wav')
        self.assertTrue(os.path.exists(downloaded_path))

        # 删除临时文件
        os.remove(file_path)
        os.remove(downloaded_path)

    def test_upload_and_delete_additional_profile_audio(self):
        # 创建一个临时文件
        file_path = 'additional_audio.wav'
        with open(file_path, 'wb') as f:
            f.write(os.urandom(512))  # 创建一个 512 字节的随机文件

        uid = '12345'

        # 上传文件
        upload_additional_profile_audio(file_path, uid)

        # 确认文件存在
        recordings = get_additional_profile_recordings(uid, download=False)
        self.assertTrue(any(file_path.split('/')[-1] in rec for rec in recordings))

        # 删除文件
        delete_additional_profile_audio(uid, os.path.basename(file_path))
        recordings_after_deletion = get_additional_profile_recordings(uid, download=False)
        self.assertFalse(any(file_path.split('/')[-1] in rec for rec in recordings_after_deletion))

        # 删除临时文件
        os.remove(file_path)

    def test_user_person_speech_sample(self):
        # 创建一个临时文件
        file_path = 'person_audio.wav'
        with open(file_path, 'wb') as f:
            f.write(os.urandom(256))  # 创建一个 256 字节的随机文件

        uid = '12345'
        person_id = '67890'

        # 上传语音文件
        upload_user_person_speech_sample(file_path, uid, person_id)

        # 验证文件存在
        samples = get_user_person_speech_samples(uid, person_id, download=False)
        self.assertTrue(any(file_path.split('/')[-1] in sample for sample in samples))

        # 删除文件
        delete_user_person_speech_sample(uid, person_id, os.path.basename(file_path))
        samples_after_deletion = get_user_person_speech_samples(uid, person_id, download=False)
        self.assertFalse(any(file_path.split('/')[-1] in sample for sample in samples_after_deletion))

        # 删除临时文件
        os.remove(file_path)

    def test_upload_and_get_signed_url(self):
        # 创建一个临时文件
        file_path = 'test_signed_url_audio.wav'
        with open(file_path, 'wb') as f:
            f.write(os.urandom(512))  # 创建一个 512 字节的随机文件

        uid = '12345'

        # 上传文件
        upload_profile_audio(file_path, uid)

        # 获取签名URL
        signed_url = create_signed_postprocessing_audio_url(file_path)
        self.assertIn("https://", signed_url)

        # 删除临时文件
        os.remove(file_path)

    # 添加其他测试...


if __name__ == '__main__':
    unittest.main()
