# -*- coding: UTF-8 -*-
"""
Filename: interface_template
Author: lilinzhen
Version: 2020/7/31
Description: TODO
"""
import requests
import json
import datetime

host = "http://127.0.0.1:8803"

headers = {
    "Content-Type": "application/json;charset=UTF-8"
}

TENANT = "hogwarts"
MODULE = "mail"
DOC_NUM = 2
API_V1 = "api/v1"


def prepare_to_odin():
    """
    :return:
    """
    tenant = TENANT

    for app_index in range(DOC_NUM):
        app_name = MODULE + str(app_index)
        add_doc_to_odin(host, tenant, MODULE, None)

    print("done")


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
    url = "{}/{}/{}/{}/zhihu/question".format(host, API_V1, tenant, module)
    data = {
        "questionId": 392341470,
        "title": "能看看我的scl90吗？",
        "author": "知乎用户",
        "answerCount": 2,
        "tag": "抑郁症/心理测试/SCL-90量表/对抗抑郁/轻度抑郁症",
        "titleDetail": "能看看我的scl90吗？我在今年去年12月的时候 去过医院就诊一次。医生给我的结果是重度抑郁。但是我当时的状态比平常差很多。而且我本人平时其实没有过什么自残行为。而且我是高三的 害怕影响学习 所以医生给我开了阿美宁 至今没有吃。只吃了中成药。有一定的神经衰弱现象 不过现在开始怀疑自己有没有误诊的成分。今天自己又做了一次 状态比较好（比较平静 偶尔会比较开心 。没有明显的失落 。躯体化症状可能注意力涣散比较严重 其他可能有我没注意到 最近有在锻炼 失眠有所改善了 非常感谢",
        "createdTime": "2020-05-03 07:31:39"
    }

    response = requests.post(url, data=json.dumps(data), headers=headers)
    print(response.content)


if __name__ == "__main__":
    print("-------begin main-------")
    a = datetime.datetime.now()
    # while True:
    #     prepare_to_odin()
    #     time.sleep(10)
    b = datetime.datetime.now()
    print('start time:%s,end time:%s,use time:%s' % (a, b, (b - a)))
    print("-------end main-------")
