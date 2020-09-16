import 'package:flutter/material.dart';
import 'package:flutter_admin/api/userInfoApi.dart';
import 'package:flutter_admin/components/cryButton.dart';
import 'package:flutter_admin/components/cryDataTable.dart';
import 'package:flutter_admin/components/cryDialog.dart';
import 'package:flutter_admin/components/form2/cryInput.dart';
import 'package:flutter_admin/components/form2/crySelect.dart';
import 'package:flutter_admin/data/data1.dart';
import 'package:flutter_admin/generated/l10n.dart';
import 'package:flutter_admin/models/configuration.dart';
import 'package:flutter_admin/models/orderItem.dart';
import 'package:flutter_admin/models/page.dart';
import 'package:flutter_admin/models/requestBodyApi.dart';
import 'package:flutter_admin/models/responeBodyApi.dart';
import 'package:flutter_admin/models/userInfo.dart';
import 'package:flutter_admin/pages/userInfo/userInfoEdit.dart';
import 'package:flutter_admin/utils/dictUtil.dart';

class UserInfoList extends StatefulWidget {
  UserInfoList({Key key}) : super(key: key);

  @override
  _UserInfoListState createState() => _UserInfoListState();
}

class _UserInfoListState extends State<UserInfoList> {
  final GlobalKey<CryDataTableState> tableKey = GlobalKey<CryDataTableState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  PageModel page;
  UserInfo userInfo = UserInfo();

  @override
  void initState() {
    super.initState();
    page = PageModel(orders: [OrderItem(column: 'update_time')]);

    WidgetsBinding.instance.addPostFrameCallback((c) {
      _query();
    });
  }

  @override
  Widget build(BuildContext context) {
    var form = Form(
      key: formKey,
      child: Wrap(
        children: <Widget>[
          CryInput(
            width: 400,
            label: '用户名称',
            value: userInfo.name,
            onSaved: (v) {
              userInfo.name = v;
            },
          ),
          CrySelect(
              width: 400,
              label: '部门',
              value: userInfo.deptId,
              dataList: Configuration.of(context).locale == 'en' ? deptIdList_en : deptIdList,
              onSaved: (v) {
                userInfo.deptId = v;
              }),
        ],
      ),
    );
    CryDataTable table = CryDataTable(
      key: tableKey,
      title: '用户管理',
      page: page,
      onPageChanged: _onPageChanged,
      onSelectChanged: (Map selected) {
        this.setState(() {});
      },
      columns: [
        DataColumn(
          label: Text(S.of(context).operating),
        ),
        DataColumn(
          label: Text(S.of(context).name),
          onSort: (int columnIndex, bool ascending) => _sort('name'),
        ),
        DataColumn(
          label: Text(S.of(context).personNickname),
          onSort: (int columnIndex, bool ascending) => _sort('nick_name'),
        ),
        DataColumn(
          label: Text(S.of(context).personGender),
          onSort: (int columnIndex, bool ascending) => _sort('gender'),
        ),
        DataColumn(
          label: Text(S.of(context).personBirthday),
          onSort: (int columnIndex, bool ascending) => _sort('birthday'),
        ),
        DataColumn(
          label: Text(S.of(context).personDepartment),
          onSort: (int columnIndex, bool ascending) => _sort('dept_id'),
        ),
        DataColumn(
          label: Text(S.of(context).creationTime),
          onSort: (int columnIndex, bool ascending) => _sort('create_time'),
        ),
        DataColumn(
          label: Text(S.of(context).updateTime),
          onSort: (int columnIndex, bool ascending) => _sort('update_time'),
        ),
      ],
      getCells: (Map m) {
        UserInfo userInfo = UserInfo.fromJson(m);
        return [
          DataCell(
            Container(
              width: 60,
              child: ButtonBar(
                children: [
                  CryButton(iconData: Icons.edit, tip: '编辑', onPressed: () => _edit(userInfo)),
                ],
              ),
            ),
          ),
          DataCell(Text(userInfo.name ?? '--')),
          DataCell(Text(userInfo.nickName ?? '--')),
          DataCell(Text(
            DictUtil.getDictName(
              userInfo.gender,
              Configuration.of(context).locale == 'en' ? genderList_en : genderList,
            ),
          )),
          DataCell(Text(userInfo.birthday ?? '--')),
          DataCell(Text(
            DictUtil.getDictName(
              userInfo.deptId,
              Configuration.of(context).locale == 'en' ? deptIdList_en : deptIdList,
              defaultValue: '--',
            ),
          )),
          DataCell(Text(userInfo.createTime ?? '--')),
          DataCell(Text(userInfo.updateTime ?? '--')),
        ];
      },
    );
    List<UserInfo> selectedList =
        tableKey?.currentState?.getSelectedList(page)?.map<UserInfo>((e) => UserInfo.fromJson(e))?.toList() ?? [];
    ButtonBar buttonBar = ButtonBar(
      alignment: MainAxisAlignment.start,
      children: <Widget>[
        CryButton(label: '查询', onPressed: () => _query()),
        CryButton(label: '重置', onPressed: () => _reset()),
        CryButton(label: '增加', onPressed: () => _add()),
        CryButton(label: '编辑', onPressed: selectedList.length != 1 ? null : () => _edit(selectedList[0])),
      ],
    );
    var result = Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 10),
          form,
          buttonBar,
          Expanded(
            child: table,
          ),
        ],
      ),
    );
    return result;
  }

  _add() {
    cryDialog(
      context: context,
      title: S.of(context).increase,
      body: UserInfoEdit(),
    ).then((v) {
      if (v != null) {
        _sort('create_time', ascending: false);
      }
    });
  }

  _edit(UserInfo userInfo) {
    cryDialog(
      context: context,
      title: userInfo == null ? S.of(context).increase : S.of(context).modify,
      body: UserInfoEdit(
        userInfo: userInfo,
      ),
    ).then((v) {
      if (v != null) {
        _sort('update_time', ascending: false);
      }
    });
  }

  _reset() {
    userInfo = UserInfo();
    _loadData();
  }

  _query() {
    formKey.currentState.save();
    _loadData();
  }

  _loadData() async {
    RequestBodyApi requestBodyApi = RequestBodyApi();
    requestBodyApi.params = userInfo.toJson();
    requestBodyApi.page = page;
    ResponeBodyApi responeBodyApi = await UserInfoApi.page(requestBodyApi);
    page = PageModel.fromJson(responeBodyApi.data);

    setState(() {});
  }

  _sort(column, {ascending}) {
    page.orders[0].column = column;
    page.orders[0].asc = ascending ?? !page.orders[0].asc;
    _query();
  }

  _onPageChanged(int size, int current) {
    page.size = size;
    page.current = current;
    _query();
  }
}
