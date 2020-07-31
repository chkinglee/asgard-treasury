# -*- coding: UTF-8 -*-
"""
Filename: locust_template
Author: lilinzhen
Version: 2020/7/31
Description: TODO
"""
import json
import time

import requests
from locust import TaskSet, task, User

headers = {
    "Content-Type": "application/json;charset=UTF-8"
}
host = "http://127.0.0.1:8803"
API_V = "api/v1"
tenant = "hogwarts"
module = "mail"


def generate_data_list():
    start_timestamp = int(time.time())
    while True:
        data = {
            "questionId": 392341470,
            "title": "能看看我的scl90吗？",
            "author": "知乎用户",
            "answerCount": 2,
            "tag": "抑郁症/心理测试/SCL-90量表/对抗抑郁/轻度抑郁症",
            "titleDetail": "能看看我的scl90吗？我在今年去年12月的时候 去过医院就诊一次。医生给我的结果是重度抑郁。但是我当时的状态比平常差很多。而且我本人平时其实没有过什么自残行为。而且我是高三的 害怕影响学习 所以医生给我开了阿美宁 至今没有吃。只吃了中成药。有一定的神经衰弱现象 不过现在开始怀疑自己有没有误诊的成分。今天自己又做了一次 状态比较好（比较平静 偶尔会比较开心 。没有明显的失落 。躯体化症状可能注意力涣散比较严重 其他可能有我没注意到 最近有在锻炼 失眠有所改善了 非常感谢",
            "createdTime": start_timestamp
        }

        print(start_timestamp)
        yield data


def add_doc_to_odin(host, tenant, module, data):
    """

    :param host:
    :param tenant:
    :param module:
    :param data:
    :return:
    """
    # if tenant == "" or tenant is None:
    #     url = "{}/{}/{}/{}/zhihu/question".format(host, API_V1, tenant, module)
    url = "{}/{}/{}/{}/zhihu/question".format(host, API_V, tenant, module)

    response = requests.post(url, data=json.dumps(data), headers=headers)
    print(response.content)


data_maker = generate_data_list()


class WebsiteTasks(TaskSet):
    """
    压测任务
    """

    @task
    def index(self):
        data = next(data_maker)
        add_doc_to_odin(host, tenant, module, data)


class WebsiteUser(User):
    tasks = [WebsiteTasks]
    min_wait = 0
    max_wait = 0
    host = host
