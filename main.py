"""
Test
A Class Widgets plugin.
"""

import json
from datetime import datetime
from pathlib import Path

from ClassWidgets.SDK import CW2Plugin, PluginAPI
from PySide6.QtCore import Signal, Slot, QTimer
from loguru import logger


class Plugin(CW2Plugin):
    contentUpdated = Signal(str)

    def __init__(self, api: PluginAPI):
        super().__init__(api)
        self.plugin_dir = Path(__file__).parent
        self.data_dict = None
        self.duty_names = "加载中..."

    def load_data_from_json(self):
        """加载 JSON 数据，返回 (start_date, data_list) 或 (None, None)"""
        json_path = self.plugin_dir / "duty.json"
        if not json_path.exists():
            logger.error("未找到 duty.json 文件，请先设置duty.json!")
            return None, None

        try:
            with open(json_path, 'r', encoding='utf-8') as f:
                self.data_dict = json.load(f)
            return self.data_dict['start_date'], self.data_dict['data']
        except (KeyError, json.JSONDecodeError) as e:
            logger.error(f"duty.json 格式错误: {e}")
            self.data_dict = None
            return None, None

    def get_current_day_index(self, start_date_str: str) -> int | None:
        """计算当天在值日表中的索引，周末返回 None"""
        start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
        current_date = datetime.now()
        if current_date.weekday() == 5:
            return None
        else:
            delta_days = (current_date - start_date).days
            return delta_days % len(self.data_dict['data'])
        
    @Slot()
    def update_duty_info(self):
        """更新值日生信息并发射信号"""
        start_date_str, data_list = self.load_data_from_json()
        if start_date_str is None:
            self.duty_names = "数据文件缺失或格式错误"
        else:
            index = self.get_current_day_index(start_date_str)
            if index is None:
                self.duty_names = "无值日生"
            else:
                self.duty_names = "\n".join(data_list[index])
        QTimer.singleShot(0, lambda: self.contentUpdated.emit(self.duty_names))

    def on_load(self):
        super().on_load()
        self.api.widgets.register(
            widget_id="widget_duty",
            name="今日值日生",
            qml_path="qml/duty_widget.qml",
            backend_obj=self
        )

        logger.success('值日生插件加载成功！本插件开发者：月下的桃子')

    def on_unload(self):
        print(f"Test unloaded")
