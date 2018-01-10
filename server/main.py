import tornado.ioloop # type: ignore
import tornado.web # type: ignore
import tornado.websocket # type: ignore

import json
import secrets

from typing import List, Dict, Any, Tuple
from enum import Enum, auto
from zipper import Zipper

class Set(object):
    def __init__(self, question: str, answers: List[str], correct_answer: str) -> None:
        self.question = question
        self.answers = answers
        self.correct_answer = correct_answer

    def is_correct(self, answer: str) -> bool:
        return answer == self.correct_answer

    def __str__(self):
        f'{self.question}: {self.answers}'

    def to_json(self) -> Dict[str, Any]:
        return {
            'question': self.question,
            'answers': self.answers
        }

class AutoName(Enum):
    def _generate_next_value_(name, start, count, last_values):
        return name


class Response(AutoName):
    OPENED = auto()
    CURRENT_QUESTION = auto()
    ANSWER_SET = auto()
    CURRENT_PLAYER_COUNT = auto()
    CURRENT_PLAYER_NAMES = auto()
    NEXT_QUESTION = auto()
    QUESTIONS_INFO = auto()
    NO_SUCH_ROOM = auto()


class Request(AutoName):
    CURRENT_QUESTION = auto() 
    SET_ANSWER = auto()
    JOIN_ROOM = auto()



class Engine(object):
    def __init__(self) -> None:
        self.questions = Zipper(
            Set("What is your name?", ["a", "b", "c", "d"], "b"),
            [ Set("Is this the next question?", ["yes", "no", "maybe", "what's it to you?"], "yes") ]
        )
        
    def next_question(self) -> None:
        self.questions.next()

    @property
    def current_question(self):
        return self.questions.current


class Room(object):
    def __init__(self, key=None) -> None:
        self.engine = Engine()
        self.active_connections : List[EchoWebSocket] = []
        self.key = key 

    def publish_message(self, message: str) -> None:
        for connection in self.active_connections:
            connection.publish(message)

    def add_connection(self, connection: Any) -> None:
        print('adding connection..')
        self.active_connections.append(connection)

        connection.answer = None

        self.send_response_to_single(Response.CURRENT_QUESTION, connection)
        self.send_response_to_all(Response.CURRENT_PLAYER_COUNT)
        self.send_response_to_all(Response.CURRENT_PLAYER_NAMES)
        self.send_response_to_all(Response.QUESTIONS_INFO)

    def remove_connection(self, connection: Any) -> None:
        self.active_connections.remove(connection)
        self.send_response_to_all(Response.CURRENT_PLAYER_COUNT)

    @property
    def all_answered(self):
        return all (connection.answer is not None for connection in self.active_connections)

    @property
    def number_of_active_connections(self) -> int:
        return len(self.active_connections)

    def make_response_json(self, response: Response) -> str:
        type_ = response.name
        props: Dict[str, Any] = {}

        if response is Response.OPENED:
            pass
        
        elif response is Response.CURRENT_QUESTION:
            props.update(self.engine.current_question.to_json())
        
        elif response is Response.ANSWER_SET:
            pass
        
        elif response is Response.CURRENT_PLAYER_COUNT:
            props.update({'count': self.number_of_active_connections})

        elif response is Response.CURRENT_PLAYER_NAMES:
            props.update({'names': [con.name for con in self.active_connections] })
            print('sending', props)
        elif response is Response.NEXT_QUESTION:
            type_ = Response.CURRENT_QUESTION.name
            props.update(self.engine.current_question.to_json())
        
        elif response is Response.QUESTIONS_INFO:
            props.update({
                'amount': self.engine.questions.size,
                'index': self.engine.questions.current_index
            })

        return json.dumps({
            "response": type_, 
            "props": props 
        })

    def process_request(self, connection: Any, request: Request, args: Dict[str, Any]) -> None:
        if request is Request.CURRENT_QUESTION:
            self.send_response_to_single(Response.CURRENT_QUESTION, connection)
        elif request is Request.SET_ANSWER:
            connection.answer = args['answer']
            self.send_response_to_single(Response.ANSWER_SET, connection)

            if self.all_answered:
                self.engine.next_question()
                self.send_response_to_all(Response.NEXT_QUESTION)
                self.send_response_to_all(Response.QUESTIONS_INFO)

    def send_response_to_all(self, response: Response):
        self.publish_message(self.make_response_json(response))

    def send_response_to_single(self, response: Response, connection):
        connection.write_message(self.make_response_json(response))


def parse_request_json(request: str) -> Tuple[Request, Any]:
    as_json = json.loads(request)

    if 'request' not in as_json:
        if 'JOIN_ROOM' in as_json:
            return (Request.JOIN_ROOM, as_json['JOIN_ROOM'])
        return None

    request = as_json['request']

    if request == 'CURRENT_QUESTION':
        return (Request.CURRENT_QUESTION, None)
    elif request == 'SET_ANSWER':
        return (Request.SET_ANSWER, as_json['props'])

    return None

rooms : List[Room] = []

def create_new_room() -> Room:
    global rooms 

    known_keys = [room.key for room in rooms]

    while True:
        token = secrets.token_hex(4)
        if token not in known_keys:
            break

    new_room = Room(token)
    rooms.append(new_room)
    return new_room


def find_room(room_key: str) -> Room:
    global rooms 
    print(rooms)

    for room in rooms:
        if room.key == room_key:
            return room 

    return None 


class EchoWebSocket(tornado.websocket.WebSocketHandler):
    def set_default_headers(self):
        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Headers", "x-requested-with")
        self.set_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')

    def check_origin(self, origin):
        return True

    def publish(self, message: str) -> None:
        self.write_message(message)

    def open(self):
        self.room = None

    @property 
    def name(self):
        return 'Jim'

    def on_message(self, message):
        parsed = parse_request_json(message)
        print('Got request', parsed)

        if parsed is None:
            return

        (request, args) = parsed
        
        if request is Request.JOIN_ROOM:
            self.room = find_room(args)
            if self.room is None:
                self.publish(json.dumps({
                    'response':'NO_SUCH_ROOM'
                }))
                return 
                
            self.room.add_connection(self)
            return
        elif self.room is None:
            return

        self.room.process_request(self, request, args)

    def on_close(self):
        if self.room is None:
            return 
        self.room.remove_connection(self)


class CreateRoomHandler(tornado.web.RequestHandler):
    def set_default_headers(self):
        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Headers", "x-requested-with")
        self.set_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')

    def check_origin(self, origin):
        return True

    def get(self):
        room = create_new_room()
        self.write(json.dumps({
            'room_name': room.key
        }))


class JoinRoomHandler(tornado.web.RequestHandler):
    def set_default_headers(self):
        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Headers", "x-requested-with")
        self.set_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')

    def check_origin(self, origin):
        return True

    def get(self):
        room_key = self.get_query_argument('room_key')
        room = find_room(room_key)

        if room is None:
            self.write(json.dumps({
                'error': 'Room not found'
            }))
        else:
            self.write(json.dumps({
            }))


if __name__ == "__main__":
    import sh 
    import os 

    os.chdir("../")
    elm_make = sh.Command("elm-make")
    output = elm_make("src/Page/Main.elm", output="elm.js")
    os.chdir("server")
    print(output)
    print('Finished building Elm file..')

    settings = {
        'debug': True, 
        'static_path': '../'
    }
    application = tornado.web.Application([
        (r"/websocket", EchoWebSocket),
        (r"/create_room", CreateRoomHandler),
        (r"/join_room", JoinRoomHandler),
    ], **settings)

    print('Listening on http://localhost:8888..')
    application.listen(8888)
    tornado.ioloop.IOLoop.current().start()